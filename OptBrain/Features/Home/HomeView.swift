import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.palette) private var palette
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsBar
                    testGrid
                    if !sessions.isEmpty {
                        recentSessionsCard
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle(greetingTitle)
            .background(Color(.systemBackground))
        }
    }

    private var greetingTitle: LocalizedStringKey {
        switch TimeOfDay.bucket(for: .now) {
        case .morning:   return "home.greeting.morning"
        case .afternoon: return "home.greeting.afternoon"
        case .evening:   return "home.greeting.evening"
        case .night:     return "home.greeting.night"
        }
    }

    // MARK: - Slim stats bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statPill(value: "\(sessions.filter { Calendar.current.isDateInToday($0.startTime) }.count)",
                     labelKey: "home.stat.today")
            divider
            statPill(value: "\(sessionsThisWeek)", labelKey: "home.stat.week")
            divider
            statPill(value: "\(currentStreak)", labelKey: "home.stat.streak")
        }
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func statPill(value: String, labelKey: String) -> some View {
        VStack(spacing: 4) {
            Text(LocalizedStringKey(labelKey))
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.onSurfaceMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.onSurface)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Theme.divider).frame(width: 1, height: 28)
    }

    // MARK: - Test grid (2x2)

    private var testGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TestType.allCases) { type in
                NavigationLink {
                    destination(for: type)
                } label: {
                    testCard(for: type)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func testCard(for type: TestType) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: type.symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(type.displayKey))
                    .font(.headline)
                    .foregroundStyle(Theme.onSurface)
                Text(LocalizedStringKey(type.subtitleKey))
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    // MARK: - Recent sessions (with precise time)

    private var recentSessionsCard: some View {
        let recent = Array(sessions.prefix(5))
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("home.recent.title").font(.headline)
                ForEach(recent, id: \.sessionId) { session in
                    sessionRow(session)
                    if session.sessionId != recent.last?.sessionId { Divider() }
                }
            }
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: 10) {
            Image(systemName: session.testType.symbol)
                .foregroundStyle(palette.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(session.testType.displayKey))
                    .font(.subheadline.weight(.semibold))
                Text(preciseTime(for: session.startTime))
                    .font(.caption)
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .monospacedDigit()
            }
            Spacer()
            sessionMetric(for: session)
        }
    }

    @ViewBuilder
    private func sessionMetric(for session: Session) -> some View {
        // Show the most representative metric for each test type, with a label
        // so the unit reads as "avg response", "completion", etc.
        if let rt = session.meanResponseTimeMs {
            VStack(alignment: .trailing, spacing: 2) {
                Text("metric.avgResponse")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .textCase(.uppercase)
                    .tracking(0.4)
                Text(String(format: "%.0f ms", rt))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.onSurface)
            }
        } else if let c = session.completionTimeMs {
            VStack(alignment: .trailing, spacing: 2) {
                Text("metric.completion")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .textCase(.uppercase)
                    .tracking(0.4)
                Text(String(format: "%.1f s", c / 1000))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.onSurface)
            }
        }
    }

    private func preciseTime(for date: Date) -> String {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        if cal.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if cal.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return NSLocalizedString("home.recent.yesterday", comment: "") + " · " + formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Streak / weekly counts

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

    // MARK: - Routing

    @ViewBuilder
    private func destination(for type: TestType) -> some View {
        switch type {
        case .reactionTime: ReactionTimeView()
        case .stroop:       StroopView()
        case .numberOrder:  NumberOrderView()
        case .memoryMatch:  MemoryMatchView()
        }
    }
}
