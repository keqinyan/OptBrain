import SwiftUI
import SwiftData

struct ReactionTimeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ReactionTimeViewModel()

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { vm.handleTap() }
            content
                .padding()
        }
        .navigationTitle("test.reactionTime.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .idle = vm.phase { /* wait for tap to begin */ }
        }
        .onDisappear { vm.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            switch vm.phase {
            case .idle:
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white)
                    Text("test.reactionTime.tapToStart")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("test.reactionTime.instructions")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 40)
                }
                Spacer()
            case .waiting:
                Spacer()
                Text("test.reactionTime.wait")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            case .go:
                Spacer()
                Text("test.reactionTime.tapNow")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            case .feedback(let rt, let falseStart):
                Spacer()
                if falseStart {
                    Text("test.reactionTime.falseStart")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                } else if rt > 0 {
                    Text(String(format: "%.0f ms", rt))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("test.reactionTime.missed")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            case .finished(let summary):
                FinishedView(summary: summary) {
                    vm.persist(in: context)
                    dismiss()
                }
            }
            if !vm.phase.isFinished {
                ProgressIndicator(current: vm.currentTrial, total: vm.totalTrials)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch vm.phase {
        case .idle, .finished:
            Color.black
        case .waiting:
            Color(.darkGray)
        case .go:
            Color(.systemGreen)
        case .feedback(_, let falseStart):
            falseStart ? Color(.systemRed) : Color(.systemBlue)
        }
    }
}

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 12)
    }
}

struct FinishedView: View {
    let summary: AnalyticsService.Summary
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("test.finished.title")
                .font(.optDashboardTitle)
                .foregroundStyle(.white)
            HStack(spacing: 12) {
                MetricTile(
                    labelKey: "metric.speed",
                    value: summary.meanResponseTimeMs.map { String(format: "%.0f ms", $0) } ?? "—",
                    symbol: "bolt.fill")
                MetricTile(
                    labelKey: "metric.accuracy",
                    value: summary.accuracy.map { String(format: "%.0f%%", $0 * 100) } ?? "—",
                    symbol: "target")
                MetricTile(
                    labelKey: "metric.stability",
                    value: summary.stabilityCV.map { String(format: "%.2f", $0) } ?? "—",
                    symbol: "waveform.path.ecg")
            }
            Button("test.finished.save", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
