import Foundation

/// Rule-based insight generation. Threshold-gated by sample size.
/// Copy is deliberately hedged - "your data suggests..." - never prescriptive.
struct InsightsService {

    struct Insight: Identifiable, Hashable {
        let id = UUID()
        let titleKey: String
        let bodyKey: String
        let bodyArgs: [String]
    }

    /// Minimum number of distinct sessions before any insight is produced.
    static let minSessionsForInsights = 7

    /// Minimum number of buckets that must have data before time-of-day claims.
    static let minBucketsForTimeOfDay = 2

    static func generate(sessions: [Session]) -> [Insight] {
        guard sessions.count >= minSessionsForInsights else {
            return [Insight(
                titleKey: "insights.notEnoughData.title",
                bodyKey: "insights.notEnoughData.body",
                bodyArgs: ["\(minSessionsForInsights)"]
            )]
        }

        var insights: [Insight] = []

        for testType in TestType.allCases {
            let typeSessions = sessions.filter { $0.testType == testType }
            guard typeSessions.count >= 3 else { continue }

            // Best time-of-day for speed.
            let speedByTOD = AnalyticsService.meanRTByTimeOfDay(sessions: typeSessions, testType: testType)
            if speedByTOD.count >= minBucketsForTimeOfDay,
               let best = speedByTOD.min(by: { $0.value < $1.value }) {
                insights.append(Insight(
                    titleKey: "insights.bestTOD.title",
                    bodyKey: "insights.bestTOD.body",
                    bodyArgs: [
                        NSLocalizedString(testType.displayKey, comment: ""),
                        NSLocalizedString(best.key.displayKey, comment: "")
                    ]
                ))
            }

            // Worst stability time-of-day.
            let stabilityByTOD = AnalyticsService.stabilityByTimeOfDay(sessions: typeSessions, testType: testType)
            if stabilityByTOD.count >= minBucketsForTimeOfDay,
               let worst = stabilityByTOD.max(by: { $0.value < $1.value }) {
                insights.append(Insight(
                    titleKey: "insights.worstStability.title",
                    bodyKey: "insights.worstStability.body",
                    bodyArgs: [
                        NSLocalizedString(testType.displayKey, comment: ""),
                        NSLocalizedString(worst.key.displayKey, comment: "")
                    ]
                ))
            }

            // Change from personal baseline (latest vs prior 7-day mean).
            if let latest = typeSessions.sorted(by: { $0.startTime > $1.startTime }).first,
               let latestRT = latest.meanResponseTimeMs,
               let baseline = AnalyticsService.baselineMeanRT(
                    sessions: typeSessions.filter { $0.sessionId != latest.sessionId },
                    testType: testType,
                    now: latest.startTime
               ),
               baseline > 0 {
                let delta = (latestRT - baseline) / baseline
                if abs(delta) >= 0.10 {
                    let key = delta < 0 ? "insights.fasterThanBaseline.body" : "insights.slowerThanBaseline.body"
                    insights.append(Insight(
                        titleKey: "insights.baselineShift.title",
                        bodyKey: key,
                        bodyArgs: [
                            NSLocalizedString(testType.displayKey, comment: ""),
                            String(format: "%.0f", abs(delta) * 100)
                        ]
                    ))
                }
            }
        }

        if insights.isEmpty {
            insights.append(Insight(
                titleKey: "insights.noStrongClaims.title",
                bodyKey: "insights.noStrongClaims.body",
                bodyArgs: []
            ))
        }
        return insights
    }
}
