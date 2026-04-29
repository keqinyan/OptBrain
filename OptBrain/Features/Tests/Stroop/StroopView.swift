import SwiftUI
import SwiftData

struct StroopView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var vm = StroopViewModel()

    var body: some View {
        VStack(spacing: 24) {
            switch vm.phase {
            case .idle:
                idleView
            case .running:
                runningView
            case .finished(let summary):
                FinishedView(summary: summary) {
                    vm.persist(in: context)
                    dismiss()
                }
                .padding()
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("test.stroop.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(palette.accent)
            Text("test.stroop.instructions")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("test.stroop.start") { vm.begin() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var runningView: some View {
        VStack(spacing: 32) {
            ProgressView(value: Double(vm.currentTrial), total: Double(vm.totalTrials))
                .tint(palette.accent)

            Spacer()
            Text(LocalizedStringKey(vm.stimulus.word.labelKey))
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(vm.stimulus.ink.color)
                .accessibilityLabel(Text(LocalizedStringKey(vm.stimulus.word.labelKey)))
            Spacer()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(StroopViewModel.InkColor.allCases, id: \.self) { c in
                    Button {
                        vm.choose(c)
                    } label: {
                        Text(LocalizedStringKey(c.labelKey))
                            .font(.title3.weight(.semibold))
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(c.color.opacity(0.18))
                            .foregroundStyle(Theme.onSurface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                }
            }
        }
    }
}
