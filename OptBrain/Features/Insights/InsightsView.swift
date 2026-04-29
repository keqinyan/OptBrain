import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.palette) private var palette
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]
    @State private var chartTestType: TestType = .reactionTime
    @State private var chartMetric: ChartMetric = .speed

    enum ChartMetric: String, CaseIterable {
        case speed, accuracy, stability
        var labelKey: String {
            switch self {
            case .speed: return "metric.speed"
            case .accuracy: return "metric.accuracy"
            case .stability: return "metric.stability"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    overviewCard
                    trendCard
                    insightsSection
                    timeOfDaySection
                }
                .padding()
            }
            .navigationTitle("insights.title")
        }
    }

    private var overviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("insights.overview.title").font(.headline)
                Text("insights.overview.note")
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)
                ForEach(TestType.allCases) { type in
                    let typeSessions = sessions.filter { $0.testType == type }
                    if !typeSessions.isEmpty {
                        overviewRow(type: type, sessions: typeSessions)
                        if type != TestType.allCases.last {
                            Divider()
                        }
                    }
                }
                if sessions.isEmpty {
                    Text("insights.overview.empty")
                        .font(.callout)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
        }
    }

    @ViewBuilder
    private func overviewRow(type: TestType, sessions: [Session]) -> some View {
        let rt = AnalyticsService.mean(of: sessions.compactMap { $0.meanResponseTimeMs })
        let acc = AnalyticsService.mean(of: sessions.compactMap { $0.accuracy })
        let cv = AnalyticsService.mean(of: sessions.compactMap { $0.stabilityCV })
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: type.symbol).foregroundStyle(palette.accent)
                Text(LocalizedStringKey(type.displayKey))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("×\(sessions.count)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
            HStack(spacing: 8) {
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

    // MARK: - 7-day trend chart

    private var trendCard: some View {
        let points = trendPoints(testType: chartTestType, metric: chartMetric, days: 7)
        let isPreview = points.allSatisfy { $0.value == nil }
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("insights.trend.title").font(.headline)
                    Spacer()
                    if isPreview {
                        Text("insights.trend.preview")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.surfaceElevated)
                            .clipShape(Capsule())
                            .foregroundStyle(Theme.onSurfaceMuted)
                    }
                }

                Picker("test", selection: $chartTestType) {
                    ForEach(TestType.allCases) { t in
                        Text(LocalizedStringKey(t.displayKey)).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                Picker("metric", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { m in
                        Text(LocalizedStringKey(m.labelKey)).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                trendChart(points: points, isPreview: isPreview)
                    .frame(height: 180)

                Text(isPreview
                     ? LocalizedStringKey("insights.trend.previewBody")
                     : LocalizedStringKey("insights.trend.body"))
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
        }
    }

    @ViewBuilder
    private func trendChart(points: [TrendPoint], isPreview: Bool) -> some View {
        let display = isPreview ? previewPoints() : points
        Chart(display) { point in
            if let v = point.value {
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(NSLocalizedString(chartMetric.labelKey, comment: ""), v)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(isPreview ? Theme.onSurfaceMuted.opacity(0.5) : palette.accent)
                .lineStyle(StrokeStyle(lineWidth: isPreview ? 1.5 : 2.5,
                                       dash: isPreview ? [4, 4] : []))

                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("v", v)
                )
                .foregroundStyle(isPreview ? Theme.onSurfaceMuted.opacity(0.5) : palette.accent)
                .symbolSize(isPreview ? 30 : 60)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxisLabel(yAxisLabel)
    }

    private var yAxisLabel: String {
        switch chartMetric {
        case .speed: return "ms"
        case .accuracy: return "%"
        case .stability: return "CV"
        }
    }

    private func trendPoints(testType: TestType, metric: ChartMetric, days: Int) -> [TrendPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let start = cal.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        let typeSessions = sessions.filter { $0.testType == testType && $0.startTime >= start }

        var dailyValues: [Date: [Double]] = [:]
        for s in typeSessions {
            let day = cal.startOfDay(for: s.startTime)
            let v: Double? = {
                switch metric {
                case .speed:     return s.meanResponseTimeMs
                case .accuracy:  return s.accuracy.map { $0 * 100 }
                case .stability: return s.stabilityCV
                }
            }()
            if let v { dailyValues[day, default: []].append(v) }
        }

        return (0..<days).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: start) ?? start
            let mean = dailyValues[day].flatMap { AnalyticsService.mean(of: $0) }
            return TrendPoint(date: day, value: mean)
        }
    }

    /// Synthetic line shown before real data exists, so users can see the chart's shape.
    private func previewPoints() -> [TrendPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let base: Double = chartMetric == .accuracy ? 90 : (chartMetric == .speed ? 320 : 0.18)
        let amp: Double = chartMetric == .accuracy ? 4 : (chartMetric == .speed ? 25 : 0.04)
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: -(6 - i), to: today) ?? today
            let v = base + amp * sin(Double(i) * 0.9)
            return TrendPoint(date: d, value: v)
        }
    }

    struct TrendPoint: Identifiable {
        let date: Date
        let value: Double?
        var id: Date { date }
    }
}
