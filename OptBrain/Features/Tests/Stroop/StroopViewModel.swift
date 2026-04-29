import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class StroopViewModel {
    enum InkColor: String, CaseIterable {
        case red, green, blue, yellow

        var color: Color {
            switch self {
            case .red:    return .red
            case .green:  return .green
            case .blue:   return .blue
            case .yellow: return .yellow
            }
        }
        var labelKey: String {
            switch self {
            case .red:    return "color.red"
            case .green:  return "color.green"
            case .blue:   return "color.blue"
            case .yellow: return "color.yellow"
            }
        }
    }

    struct Stimulus {
        let word: InkColor       // the word printed
        let ink: InkColor        // the actual rendered color
        var congruent: Bool { word == ink }
    }

    enum Phase {
        case idle
        case running
        case finished(AnalyticsService.Summary)

        var isFinished: Bool {
            if case .finished = self { return true }
            return false
        }
    }

    let totalTrials: Int = 12
    private(set) var currentTrial: Int = 0
    private(set) var phase: Phase = .idle
    private(set) var stimulus: Stimulus = Stimulus(word: .red, ink: .red)

    private var startedAt: Date = .now
    private var trialStart: Date = .now
    private(set) var trials: [Trial] = []

    func begin() {
        startedAt = .now
        currentTrial = 0
        trials = []
        phase = .running
        nextStimulus()
    }

    func choose(_ choice: InkColor) {
        guard case .running = phase else { return }
        let rt = Date.now.timeIntervalSince(trialStart) * 1000
        let correct = (choice == stimulus.ink)
        let trial = Trial(
            trialIndex: currentTrial,
            responseTimeMs: rt,
            isCorrect: correct,
            stroopCongruent: stimulus.congruent
        )
        trials.append(trial)
        if currentTrial >= totalTrials {
            finish()
        } else {
            nextStimulus()
        }
    }

    private func nextStimulus() {
        currentTrial += 1
        // ~50% congruent / 50% incongruent for a balanced run.
        let word = InkColor.allCases.randomElement()!
        let ink: InkColor = Bool.random()
            ? word
            : InkColor.allCases.filter { $0 != word }.randomElement()!
        stimulus = Stimulus(word: word, ink: ink)
        trialStart = .now
    }

    private func finish() {
        let summary = AnalyticsService.summarize(trials: trials)
        phase = .finished(summary)
    }

    func persist(in context: ModelContext) {
        let summary = AnalyticsService.summarize(trials: trials)
        let session = Session(
            testType: .stroop,
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
