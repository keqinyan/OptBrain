import SwiftUI

struct MemoryMatchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var vm = MemoryMatchViewModel()

    var body: some View {
        VStack(spacing: 16) {
            switch vm.phase {
            case .idle: idleView
            case .running: runningView
            case .finished(let summary, let completion):
                finishedView(summary: summary, completion: completion)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("test.memoryMatch.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(palette.accent)
            Text("test.memoryMatch.instructions")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("test.memoryMatch.start") { vm.begin() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("test.memoryMatch.matches")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceMuted)
                Text("\(vm.matches) / \(vm.pairCount)")
                    .font(.title3.bold())
                    .monospacedDigit()
                Spacer()
                Text("metric.mistakes")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceMuted)
                Text("\(vm.mistakes)")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
            grid
            Spacer()
        }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(vm.cards.enumerated()), id: \.element.id) { index, card in
                cardView(card)
                    .onTapGesture { vm.tap(at: index) }
            }
        }
    }

    @ViewBuilder
    private func cardView(_ card: MemoryMatchViewModel.Card) -> some View {
        let revealed = card.isFaceUp || card.isMatched
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(revealed ? palette.accent.opacity(card.isMatched ? 0.18 : 0.28) : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(card.isMatched ? palette.accent : Theme.divider,
                                lineWidth: card.isMatched ? 1.5 : 1)
                )
            if revealed {
                Image(systemName: card.symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .opacity(card.isMatched ? 0.6 : 1)
            } else {
                Image(systemName: "questionmark")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.onSurfaceMuted.opacity(0.4))
            }
        }
        .aspectRatio(0.85, contentMode: .fit)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: card.isFaceUp)
    }

    private func finishedView(summary: AnalyticsService.Summary, completion: Double) -> some View {
        VStack(spacing: 12) {
            Text("test.finished.title").font(.optDashboardTitle)
            HStack(spacing: 12) {
                MetricTile(
                    labelKey: "metric.completion",
                    value: String(format: "%.1f s", completion / 1000),
                    symbol: "clock.fill")
                MetricTile(
                    labelKey: "metric.accuracy",
                    value: summary.accuracy.map { String(format: "%.0f%%", $0 * 100) } ?? "—",
                    symbol: "target")
            }
            HStack(spacing: 12) {
                MetricTile(
                    labelKey: "metric.mistakes",
                    value: "\(vm.mistakes)",
                    symbol: "xmark.octagon.fill")
                MetricTile(
                    labelKey: "metric.speed",
                    value: summary.meanResponseTimeMs.map { String(format: "%.0f ms", $0) } ?? "—",
                    symbol: "bolt.fill")
            }
            Button("test.finished.save") {
                vm.persist(in: context)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
        }
    }
}
