import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    todaySnapshot
                    streakCard
                    quickStart
                }
                .padding()
            }
            .navigationTitle("home.title")
            .background(Color(.systemBackground))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingKey)
                .font(.optDashboardTitle)
            Text("home.subtitle")
                .foregroundStyle(Theme.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingKey: LocalizedStringKey {
        switch TimeOfDay.bucket(for: .now) {
        case .morning:   return "home.greeting.morning"
        case .afternoon: return "home.greeting.afternoon"
        case .evening:   return "home.greeting.evening"
        case .night:     return "home.greeting.night"
        }
    }

    private var todaysSessions: [Session] {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.startTime) }
    }

    private var todaySnapshot: some View {
        let today = todaysSessions
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("home.today.title").font(.headline)
                    Spacer()
                    Text("metric.sessions").font(.caption).foregroundStyle(Theme.onSurfaceMuted)
                    Text("\(today.count)").font(.subheadline.bold()).monospacedDigit()
                }
                if today.isEmpty {
                    Text("home.today.empty")
                        .foregroundStyle(Theme.onSurfaceMuted)
                } else {
                    // Per-test rows: each test compares only with itself.
                    ForEach(TestType.allCases) { type in
                        let typeSessions = today.filter { $0.testType == type }
                        if !typeSessions.isEmpty {
                            todayRow(type: type, sessions: typeSessions)
                            if type != TestType.allCases.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func todayRow(type: TestType, sessions: [Session]) -> some View {
        let meanRT = AnalyticsService.mean(of: sessions.compactMap { $0.meanResponseTimeMs })
        let meanAcc = AnalyticsService.mean(of: sessions.compactMap { $0.accuracy })
        HStack(spacing: 10) {
            Image(systemName: type.symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            Text(LocalizedStringKey(type.displayKey))
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let rt = meanRT {
                Label(String(format: "%.0f ms", rt), systemImage: "bolt.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
            if let acc = meanAcc {
                Label(String(format: "%.0f%%", acc * 100), systemImage: "target")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
            Text("×\(sessions.count)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(Theme.onSurface)
        }
    }

    private var streakCard: some View {
        let count = sessionsThisWeek
        let streak = currentStreak
        return Card {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.week.title").font(.headline)
                    Text("\(count)")
                        .font(.optMetricValue)
                        .monospacedDigit()
                    Text("home.week.subtitle")
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.streak.title").font(.headline)
                    Text("\(streak)")
                        .font(.optMetricValue)
                        .monospacedDigit()
                    Text("home.streak.subtitle")
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
        }
    }

    private var sessionsThisWeek: Int {
        let cal = Calendar.current
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        return sessions.filter { $0.startTime >= weekStart }.count
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.startTime) })
        var streak = 0
        var cursor = cal.startOfDay(for: .now)
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private var quickStart: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("home.tests.title").font(.headline)
                ForEach(TestType.allCases) { type in
                    NavigationLink {
                        destination(for: type)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.symbol)
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(type.displayKey))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Theme.onSurface)
                                Text(LocalizedStringKey(type.subtitleKey))
                                    .font(.caption)
                                    .foregroundStyle(Theme.onSurfaceMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.onSurfaceMuted)
                        }
                        .padding(.vertical, 8)
                    }
                    if type != TestType.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for type: TestType) -> some View {
        switch type {
        case .reactionTime: ReactionTimeView()
        case .stroop:       StroopView()
        case .numberOrder:  NumberOrderView()
        }
    }
}
