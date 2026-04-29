import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [Session]
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showWipeConfirm = false
    @State private var showHealthSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.language") {
                    Picker("settings.language", selection: $appLanguage) {
                        Text("settings.language.system").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("settings.data") {
                    Button("settings.export.csv") { export(.csv) }
                    Button("settings.export.json") { export(.json) }
                    Button("settings.health.connect") { showHealthSheet = true }
                    Button(role: .destructive) {
                        showWipeConfirm = true
                    } label: {
                        Text("settings.wipe")
                    }
                }

                Section("settings.privacy") {
                    Text("settings.privacy.body")
                        .font(.callout)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }

                Section("settings.about") {
                    LabeledContent("settings.about.version", value: appVersion)
                    Text("settings.about.disclaimer")
                        .font(.caption)
                        .foregroundStyle(Theme.onSurfaceMuted)
                }
            }
            .navigationTitle("settings.title")
            .sheet(isPresented: $showExporter) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showHealthSheet) { HealthPermissionSheet() }
            .confirmationDialog(
                "settings.wipe.confirm.title",
                isPresented: $showWipeConfirm,
                titleVisibility: .visible
            ) {
                Button("settings.wipe.confirm.action", role: .destructive) {
                    try? PersistenceController.shared.wipeAll()
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("settings.wipe.confirm.body")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func export(_ format: ExportService.Format) {
        do {
            let url = try ExportService.export(sessions: sessions, format: format)
            self.exportURL = url
            self.showExporter = true
        } catch {
            self.exportURL = nil
        }
    }
}

private struct HealthPermissionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accent)
                Text("settings.health.title").font(.optDashboardTitle)
                Text("settings.health.body")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.onSurfaceMuted)
                Spacer()
                Button {
                    Task {
                        isWorking = true
                        try? await HealthKitService.shared.requestAuthorization()
                        isWorking = false
                        dismiss()
                    }
                } label: {
                    Text(isWorking ? "common.loading" : "settings.health.cta")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("common.notNow") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(24)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
