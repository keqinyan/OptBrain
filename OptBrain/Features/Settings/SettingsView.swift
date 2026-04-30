import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [Session]
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("themePalette") private var paletteRaw: String = ThemePalette.teal.rawValue

    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showWipeConfirm = false
    @State private var showHealthSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("settings.language", selection: $appLanguage) {
                        Text("settings.language.system").tag("system")
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: appLanguage) { _, newValue in
                        // Bundle.main.preferredLocalizations is decided at launch from
                        // AppleLanguages, so we write it immediately here. The next launch
                        // picks the right .lproj before any string lookup happens.
                        if newValue == "system" {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        }
                    }
                } header: {
                    Text("settings.language")
                } footer: {
                    Text("settings.language.restartHint")
                        .font(.caption)
                }

                Section("settings.theme") {
                    ThemePickerRow(selection: $paletteRaw)
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
    @Environment(\.palette) private var palette
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(palette.accent)
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

private struct ThemePickerRow: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 5 fixed columns × 2 rows = 10 swatches, consistent on every width.
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                spacing: 12
            ) {
                ForEach(ThemePalette.allCases) { palette in
                    swatch(for: palette)
                }
            }
            Text(LocalizedStringKey(currentPalette.displayKey))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.onSurfaceMuted)
        }
        .padding(.vertical, 6)
    }

    private var currentPalette: ThemePalette {
        ThemePalette(rawValue: selection) ?? .teal
    }

    @ViewBuilder
    private func swatch(for palette: ThemePalette) -> some View {
        let isSelected = palette.rawValue == selection
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                selection = palette.rawValue
            }
        } label: {
            ZStack {
                Circle()
                    .fill(palette.accent)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Theme.onSurface.opacity(0.08), lineWidth: 1)
                    )
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                }
            }
            .padding(4)
            .background(
                Circle()
                    .stroke(palette.accent, lineWidth: isSelected ? 2 : 0)
            )
            .scaleEffect(isSelected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(palette.displayKey)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
