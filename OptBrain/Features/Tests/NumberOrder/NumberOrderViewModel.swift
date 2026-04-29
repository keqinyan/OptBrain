import Foundation
import SwiftData

@MainActor
@Observable
final class NumberOrderViewModel {
    enum Phase {
        case idle
        case running
        case finished(AnalyticsService.Summary, completionTimeMs: Double)

        var isFinished: Bool {
            if case .finished = self { return true }
            return false
        }
    }

    let gridSize: Int
    private(set) var numbers: [Int] = []
    private(set) var nextExpected: Int = 1
    private(set) var tappedIndices: Set<Int> = []
    private(set) var mistakes: Int = 0
    private(set) var phase: Phase = .idle

    private var startedAt: Date = .now
    private var firstTapAt: Date?
    private(set) var trials: [Trial] = []

    init(gridSize: Int = 4) {
        self.gridSize = gridSize
    }

    var totalCells: Int { gridSize * gridSize }

    func begin() {
        numbers = Array(1...totalCells).shuffled()
        nextExpected = 1
        tappedIndices = []
        mistakes = 0
        trials = []
        startedAt = .now
        firstTapAt = nil
        phase = .running
    }

    func tap(at index: Int) {
        guard case .running = phase else { return }
        guard !tappedIndices.contains(index) else { return }
        let value = numbers[index]
        let now = Date.now
        if firstTapAt == nil { firstTapAt = now }

        if value == nextExpected {
            tappedIndices.insert(index)
            let rt = now.timeIntervalSince(firstTapAt ?? now) * 1000
            trials.append(Trial(
                trialIndex: nextExpected,
                responseTimeMs: rt,
                isCorrect: true,
                gridSize: gridSize
            ))
            nextExpected += 1
            if nextExpected > totalCells {
                finish()
            }
        } else {
            mistakes += 1
            trials.append(Trial(
                trialIndex: nextExpected,
                responseTimeMs: nil,
                isCorrect: false,
                gridSize: gridSize
            ))
        }
    }

    private func finish() {
        let total = Date.now.timeIntervalSince(startedAt) * 1000
        var summary = AnalyticsService.summarize(trials: trials)
        summary.mistakeCount = mistakes
        phase = .finished(summary, completionTimeMs: total)
    }

    func persist(in context: ModelContext) {
        guard case .finished(var summary, let completion) = phase else { return }
        summary.mistakeCount = mistakes
        let session = Session(
            testType: .numberOrder,
            startTime: startedAt,
            endTime: .now,
            meanResponseTimeMs: summary.meanResponseTimeMs,
            accuracy: summary.accuracy,
            stabilityCV: summary.stabilityCV,
            mistakeCount: mistakes,
            completionTimeMs: completion,
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
