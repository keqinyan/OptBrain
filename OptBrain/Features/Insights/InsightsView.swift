import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    overviewCard
                    insightsSection
                    timeOfDaySection
                }
                .padding()
            }
            .navigationTitle("insights.title")
        }
    }

    private var overviewCard: some View {
        let rt = AnalyticsService.mean(of: sessions.compactMap { $0.meanResponseTimeMs })
        let acc = AnalyticsService.mean(of: sessions.compactMap { $0.accuracy })
        let cv = AnalyticsService.mean(of: sessions.compactMap { $0.stabilityCV })
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("insights.overview.title").font(.headline)
                HStack(spacing: 12) {
                    MetricTile(
                        labelKey: "metric.speed",
                        value: rt.map { String(format: "%.0f ms", $0) } ?? "—",
                        symbol: "bolt.fill")
                    MetricTile(
                        labelKey: "metric.accuracy",
                        value: acc.map { String(format: "%.0f%%", $0 * 100) } ?? "—",
                        symbol: "target")
                    MetricTile(
                        labelKey: "metric.stability",
                        value: cv.map { String(format: "%.2f", $0) } ?? "—",
                        symbol: "waveform.path.ecg")
                }
                Text("insights.overview.note")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    private var insightsSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("insights.section.title").font(.headline)
                let insights = InsightsService.generate(sessions: sessions)
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(insight.titleKey))
                            .font(.subheadline.weight(.semibold))
                        Text(localizedBody(insight))
                            .font(.callout)
                            .foregroundStyle(Theme.onSurfaceMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if insight.id != insights.last?.id { Divider() }
                }
            }
        }
    }

    private func localizedBody(_ insight: InsightsService.Insight) -> String {
        let template = NSLocalizedString(insight.bodyKey, comment: "")
        return String(format: template, arguments: insight.bodyArgs.map { $0 as CVarArg })
    }

    private var timeOfDaySection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("insights.byTOD.title").font(.headline)
                ForEach(TestType.allCases) { type in
                    let map = AnalyticsService.meanRTByTimeOfDay(sessions: sessions, testType: type)
                    if !map.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey(type.displayKey))
                                .font(.subheadline.weight(.semibold))
                            ForEach(TimeOfDay.allCases, id: \.self) { tod in
                                if let v = map[tod] {
                                    HStack {
                                        Text(LocalizedStringKey(tod.displayKey))
                                            .foregroundStyle(Theme.onSurfaceMuted)
                                        Spacer()
                                        Text(String(format: "%.0f ms", v))
                                            .monospacedDigit()
                                    }
                                    .font(.callout)
                                }
                            }
                        }
                        if type != TestType.allCases.last { Divider() }
                    }
                }
                if sessions.isEmpty {
                    Text("insights.byTOD.empty")
                        .foregroundStyle(Theme.onSurfaceMuted)
                        .font(.callout)
                }
            }
        }
    }
}
