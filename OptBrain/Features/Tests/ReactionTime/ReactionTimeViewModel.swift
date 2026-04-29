import Foundation
import SwiftData

@MainActor
@Observable
final class ReactionTimeViewModel {
    enum Phase {
        case idle           // initial / between trials
        case waiting        // gray screen, random delay before stimulus
        case go             // green screen, awaiting tap
        case feedback(Double, Bool) // (rt ms, isFalseStart)
        case finished(AnalyticsService.Summary)

        var isFinished: Bool {
            if case .finished = self { return true }
            return false
        }
    }

    let totalTrials: Int = 5
    private(set) var currentTrial: Int = 0
    private(set) var phase: Phase = .idle

    private var startedAt: Date = .now
    private var stimulusAt: Date?
    private var pendingTask: Task<Void, Never>?
    private(set) var trials: [Trial] = []

    func begin() {
        startedAt = .now
        currentTrial = 0
        trials = []
        scheduleNextTrial()
    }

    func cancel() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    func handleTap() {
        switch phase {
        case .idle:
            scheduleNextTrial()
        case .waiting:
            // False start - tap before stimulus.
            pendingTask?.cancel()
            recordTrial(rt: nil, isCorrect: false, isFalseStart: true, isMissed: false)
            phase = .feedback(0, true)
            advanceAfterFeedback()
        case .go:
            guard let stim = stimulusAt else { return }
            let rt = Date.now.timeIntervalSince(stim) * 1000
            recordTrial(rt: rt, isCorrect: true, isFalseStart: false, isMissed: false)
            phase = .feedback(rt, false)
            advanceAfterFeedback()
        case .feedback, .finished:
            break
        }
    }

    private func scheduleNextTrial() {
        guard currentTrial < totalTrials else {
            finish()
            return
        }
        currentTrial += 1
        phase = .waiting
        let delay = Double.random(in: 1.5...3.5)
        pendingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            // If user hasn't false-started, present stimulus.
            if case .waiting = self.phase {
                self.stimulusAt = .now
                self.phase = .go
                // Give 2s to react before treating as missed.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                if case .go = self.phase {
                    self.recordTrial(rt: nil, isCorrect: false, isFalseStart: false, isMissed: true)
                    self.phase = .feedback(0, false)
                    self.advanceAfterFeedback()
                }
            }
        }
    }

    private func advanceAfterFeedback() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard let self else { return }
            self.scheduleNextTrial()
        }
    }

    private func recordTrial(rt: Double?, isCorrect: Bool, isFalseStart: Bool, isMissed: Bool) {
        let trial = Trial(
            trialIndex: currentTrial,
            responseTimeMs: rt,
            isCorrect: isCorrect,
            isFalseStart: isFalseStart,
            isMissed: isMissed
        )
        trials.append(trial)
    }

    private func finish() {
        let summary = AnalyticsService.summarize(trials: trials)
        phase = .finished(summary)
    }

    func persist(in context: ModelContext) {
        let summary = AnalyticsService.summarize(trials: trials)
        let session = Session(
            testType: .reactionTime,
            startTime: startedAt,
            endTime: .now,
            meanResponseTimeMs: summary.meanResponseTimeMs,
            accuracy: summary.accuracy,
            stabilityCV: summary.stabilityCV,
            mistakeCount: summary.mistakeCount,
            fatigueDelta: summary.fatigueDelta
        )
        context.insert(session)
        for trial in trials {
            trial.session = session
            context.insert(trial)
        }
        try? context.save()
    }
}
