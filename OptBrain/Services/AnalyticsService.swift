import Foundation

/// Pure, deterministic analytics on a Session's trial set.
/// No SwiftUI, no SwiftData mutations - safe to unit test.
struct AnalyticsService {

    struct Summary {
        var meanResponseTimeMs: Double?
        var accuracy: Double?
        var stabilityCV: Double?     // coefficient of variation; lower = more stable
        var mistakeCount: Int
        var fatigueDelta: Double?    // (2nd-half mean - 1st-half mean) / 1st-half mean
    }

    static func summarize(trials: [Trial]) -> Summary {
        guard !trials.isEmpty else {
            return Summary(meanResponseTimeMs: nil, accuracy: nil, stabilityCV: nil, mistakeCount: 0, fatigueDelta: nil)
        }

        let validRTs = trials.compactMap { $0.responseTimeMs }
        let mean = mean(of: validRTs)
        let sd = stdDev(of: validRTs, mean: mean)
        let cv: Double? = {
            guard let m = mean, m > 0, let sd else { return nil }
            return sd / m
        }()

        let answered = trials.filter { !$0.isMissed && !$0.isFalseStart }
        let accuracy: Double? = answered.isEmpty
            ? nil
            : Double(answered.filter(\.isCorrect).count) / Double(answered.count)

        let mistakes = trials.filter { !$0.isCorrect || $0.isFalseStart || $0.isMissed }.count

        return Summary(
            meanResponseTimeMs: mean,
            accuracy: accuracy,
            stabilityCV: cv,
            mistakeCount: mistakes,
            fatigueDelta: fatigueDelta(trials: trials)
        )
    }

    static func fatigueDelta(trials: [Trial]) -> Double? {
        let rts = trials.compactMap { $0.responseTimeMs }
        guard rts.count >= 6 else { return nil }
        let half = rts.count / 2
        let first = Array(rts.prefix(half))
        let second = Array(rts.suffix(rts.count - half))
        guard let m1 = mean(of: first), let m2 = mean(of: second), m1 > 0 else { return nil }
        return (m2 - m1) / m1
    }

    // MARK: - Aggregations across many sessions

    /// Mean response time grouped by time-of-day bucket for a single test type.
    static func meanRTByTimeOfDay(sessions: [Session], testType: TestType) -> [TimeOfDay: Double] {
        let filtered = sessions.filter { $0.testType == testType }
        var buckets: [TimeOfDay: [Double]] = [:]
        for session in filtered {
            guard let rt = session.meanResponseTimeMs else { continue }
            buckets[session.timeOfDay, default: []].append(rt)
        }
        return buckets.compactMapValues { mean(of: $0) }
    }

    /// Stability (CV) grouped by time-of-day bucket.
    static func stabilityByTimeOfDay(sessions: [Session], testType: TestType) -> [TimeOfDay: Double] {
        let filtered = sessions.filter { $0.testType == testType }
        var buckets: [TimeOfDay: [Double]] = [:]
        for session in filtered {
            guard let cv = session.stabilityCV else { continue }
            buckets[session.timeOfDay, default: []].append(cv)
        }
        return buckets.compactMapValues { mean(of: $0) }
    }

    /// 7-day rolling baseline of mean RT for the given test.
    static func baselineMeanRT(sessions: [Session], testType: TestType, now: Date = .now) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let recent = sessions.filter { $0.testType == testType && $0.startTime >= cutoff }
        let values = recent.compactMap { $0.meanResponseTimeMs }
        return mean(of: values)
    }

    // MARK: - Stats primitives

    static func mean(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func stdDev(of values: [Double], mean providedMean: Double? = nil) -> Double? {
        guard values.count >= 2 else { return nil }
        let m = providedMean ?? (mean(of: values) ?? 0)
        let sumSq = values.reduce(0) { $0 + ($1 - m) * ($1 - m) }
        return (sumSq / Double(values.count - 1)).squareRoot()
    }
}
