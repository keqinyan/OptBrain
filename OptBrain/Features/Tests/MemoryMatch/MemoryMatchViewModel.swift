import Foundation
import SwiftData

@MainActor
@Observable
final class MemoryMatchViewModel {
    enum Phase {
        case idle
        case running
        case finished(AnalyticsService.Summary, completionTimeMs: Double)
    }

    struct Card: Identifiable {
        let id = UUID()
        let symbol: String   // SF Symbol name used as the face
        var isFaceUp: Bool = false
        var isMatched: Bool = false
    }

    /// Number of pairs. 6 → 12-card 3×4 grid (default). Could be adjusted later.
    let pairCount: Int = 6
    private(set) var cards: [Card] = []
    private(set) var firstPickIndex: Int?
    private(set) var lockTaps: Bool = false
    private(set) var mistakes: Int = 0
    private(set) var matches: Int = 0
    private(set) var phase: Phase = .idle

    private var startedAt: Date = .now
    private var firstPickAt: Date?
    private(set) var trials: [Trial] = []

    /// Pool of distinct, calm SF Symbols for card faces.
    private let symbolPool: [String] = [
        "leaf.fill", "drop.fill", "flame.fill", "moon.fill",
        "sun.max.fill", "snow", "bolt.fill", "star.fill",
        "cloud.fill", "heart.fill"
    ]

    func begin() {
        let chosen = symbolPool.shuffled().prefix(pairCount)
        let pairs = chosen + chosen
        cards = pairs.shuffled().map { Card(symbol: $0) }
        firstPickIndex = nil
        lockTaps = false
        mistakes = 0
        matches = 0
        trials = []
        startedAt = .now
        firstPickAt = nil
        phase = .running
    }

    func tap(at index: Int) {
        guard case .running = phase, !lockTaps else { return }
        guard !cards[index].isMatched, !cards[index].isFaceUp else { return }

        cards[index].isFaceUp = true

        if let first = firstPickIndex {
            // Second pick of a pair attempt — record a "trial".
            let now = Date.now
            let rt = now.timeIntervalSince(firstPickAt ?? now) * 1000
            let isMatch = cards[first].symbol == cards[index].symbol
            trials.append(Trial(
                trialIndex: trials.count + 1,
                responseTimeMs: rt,
                isCorrect: isMatch
            ))

            if isMatch {
                cards[first].isMatched = true
                cards[index].isMatched = true
                matches += 1
                firstPickIndex = nil
                firstPickAt = nil
                if matches >= pairCount {
                    finish()
                }
            } else {
                mistakes += 1
                lockTaps = true
                let firstIdx = first
                let secondIdx = index
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    guard let self else { return }
                    self.cards[firstIdx].isFaceUp = false
                    self.cards[secondIdx].isFaceUp = false
                    self.firstPickIndex = nil
                    self.firstPickAt = nil
                    self.lockTaps = false
                }
            }
        } else {
            firstPickIndex = index
            firstPickAt = .now
        }
    }

    private func finish() {
        let total = Date.now.timeIntervalSince(startedAt) * 1000
        var summary = AnalyticsService.summarize(trials: trials)
        // Override mistake count with the user-facing definition.
        summary.mistakeCount = mistakes
        // Accuracy here = matches / pair attempts (matches + mistakes).
        let attempts = matches + mistakes
        summary.accuracy = attempts > 0 ? Double(matches) / Double(attempts) : nil
        phase = .finished(summary, completionTimeMs: total)
    }

    func persist(in context: ModelContext) {
        guard case .finished(let summary, let completion) = phase else { return }
        let session = Session(
            testType: .memoryMatch,
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
