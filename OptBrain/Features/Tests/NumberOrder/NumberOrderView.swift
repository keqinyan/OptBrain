import SwiftUI

struct NumberOrderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm = NumberOrderViewModel(gridSize: 4)

    var body: some View {
        VStack(spacing: 16) {
            switch vm.phase {
            case .idle: idleView
            case .running: runningView
            case .finished(let summary, let completion):
                VStack(spacing: 12) {
                    MetricTile(
                        labelKey: "metric.completion",
                        value: String(format: "%.1f s", completion / 1000),
                        symbol: "clock.fill")
                    MetricTile(
                        labelKey: "metric.mistakes",
                        value: "\(summary.mistakeCount)",
                        symbol: "xmark.octagon.fill")
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
                .padding()
            }
        }
        .padding()
        .navigationTitle("test.numberOrder.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent)
            Text("test.numberOrder.instructions")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("test.numberOrder.start") { vm.begin() }
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

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: vm.gridSize)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(vm.numbers.enumerated()), id: \.offset) { index, value in
                    Button {
                        vm.tap(at: index)
                    } label: {
                        Text("\(value)")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(vm.tappedIndices.contains(index)
                                       ? Theme.accent.opacity(0.25)
                                       : Theme.surface)
                            .foregroundStyle(vm.tappedIndices.contains(index)
                                             ? Theme.onSurfaceMuted
                                             : Theme.onSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(vm.tappedIndices.contains(index))
                }
            }
        }
    }
}
