import SwiftUI
import SwiftData

struct NumberOrderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var vm = NumberOrderViewModel(gridSize: 4)
    @State private var selectedSize: Int = 4

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
        .navigationTitle("test.numberOrder.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(palette.accent)
            Text("test.numberOrder.instructions")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                Text("test.numberOrder.gridSize")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.onSurfaceMuted)
                Picker("test.numberOrder.gridSize", selection: $selectedSize) {
                    Text("3 × 3").tag(3)
                    Text("4 × 4").tag(4)
                    Text("5 × 5").tag(5)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 24)

            Spacer()
            Button("test.numberOrder.start") {
                vm.setGridSize(selectedSize)
                vm.begin()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("test.numberOrder.next")
                    .font(.subheadline)
                    .foregroundStyle(Theme.onSurfaceMuted)
                Text("\(vm.nextExpected)")
                    .font(.title2.bold())
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: vm.gridSize)
        // Tighter font for larger grids so 2-digit numbers fit cleanly.
        let baseFont: Font.TextStyle = vm.gridSize >= 5 ? .title3 : .title2
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(vm.numbers.enumerated()), id: \.offset) { index, value in
                Button {
                    vm.tap(at: index)
                } label: {
                    cell(value: value, isTapped: vm.tappedIndices.contains(index), baseFont: baseFont)
                }
                .disabled(vm.tappedIndices.contains(index))
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func cell(value: Int, isTapped: Bool, baseFont: Font.TextStyle) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isTapped ? palette.accent.opacity(0.5) : Theme.divider.opacity(0.4),
                                      lineWidth: 1)
                )
            if isTapped {
                Image(systemName: "checkmark")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.accent)
            } else {
                Text("\(value)")
                    .font(.system(baseFont, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(Theme.onSurface)
                    .padding(4)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }

    private func finishedView(summary: AnalyticsService.Summary, completion: Double) -> some View {
        VStack(spacing: 12) {
            Text("test.finished.title")
                .font(.optDashboardTitle)
            HStack(spacing: 12) {
                MetricTile(
                    labelKey: "metric.completion",
                    value: String(format: "%.1f s", completion / 1000),
                    symbol: "clock.fill")
                MetricTile(
                    labelKey: "metric.mistakes",
                    value: "\(summary.mistakeCount)",
                    symbol: "xmark.octagon.fill")
            }
            MetricTile(
                labelKey: "metric.stability",
                value: summary.stabilityCV.map { String(format: "%.2f", $0) } ?? "—",
                symbol: "waveform.path.ecg")
            Button("test.finished.save") {
                vm.persist(in: context)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top)
        }
    }
}
