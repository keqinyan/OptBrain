import SwiftUI
import SwiftData

@main
struct OptBrainApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("themePalette") private var paletteRaw: String = ThemePalette.teal.rawValue

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .environment(\.locale, resolvedLocale)
            .environment(\.palette, currentPalette)
            .preferredColorScheme(nil)
            .tint(currentPalette.accent)
        }
        .modelContainer(PersistenceController.shared.container)
    }

    private var currentPalette: ThemePalette {
        ThemePalette(rawValue: paletteRaw) ?? .teal
    }

    private var resolvedLocale: Locale {
        switch appLanguage {
        case "en": return Locale(identifier: "en")
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        default: return .current
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("tab.home", systemImage: "house") }
            InsightsView()
                .tabItem { Label("tab.insights", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
        }
    }
}
