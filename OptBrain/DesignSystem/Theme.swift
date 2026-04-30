import SwiftUI

/// Calm, science-inspired palettes. Reads naturally in dark mode.
enum Theme {
    /// Default accent. Resolves to the asset catalog AccentColor for any view that
    /// doesn't pull `\.palette` from the environment. New code should prefer
    /// `@Environment(\.palette).accent` so user-selected palettes flow through.
    static let accent = Color("AccentColor", bundle: nil)

    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let onSurface = Color(.label)
    static let onSurfaceMuted = Color(.secondaryLabel)
    static let divider = Color(.separator)
    static let danger = Color(.systemRed)
    static let success = Color(.systemGreen)

    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
}

extension Font {
    static let optDashboardTitle: Font = .system(.largeTitle, design: .rounded, weight: .semibold)
    static let optMetricValue: Font = .system(.title3, design: .rounded, weight: .semibold)
    static let optMetricLabel: Font = .system(.caption, design: .rounded, weight: .medium)
}

// MARK: - Preset palettes

enum ThemePalette: String, CaseIterable, Identifiable {
    case teal       // default — matches the AccentColor asset
    case indigo
    case amber
    case graphite

    var id: String { rawValue }

    var displayKey: String {
        switch self {
        case .teal:     return "theme.teal"
        case .indigo:   return "theme.indigo"
        case .amber:    return "theme.amber"
        case .graphite: return "theme.graphite"
        }
    }

    /// Light + dark sRGB tuples (red, green, blue).
    private var components: (light: (Double, Double, Double), dark: (Double, Double, Double)) {
        switch self {
        case .teal:     return ((0.165, 0.616, 0.561), (0.310, 0.741, 0.667))
        case .indigo:   return ((0.231, 0.353, 0.627), (0.435, 0.553, 0.808))
        case .amber:    return ((0.890, 0.561, 0.165), (0.965, 0.694, 0.310))
        case .graphite: return ((0.298, 0.337, 0.380), (0.580, 0.620, 0.667))
        }
    }

    func accent(for scheme: ColorScheme) -> Color {
        let c = scheme == .dark ? components.dark : components.light
        return Color(red: c.0, green: c.1, blue: c.2)
    }

    /// Adaptive accent — picks the right value based on the current color scheme.
    var accent: Color {
        Color(uiColor: UIColor { trait in
            let isDark = trait.userInterfaceStyle == .dark
            let c = isDark ? self.components.dark : self.components.light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

// MARK: - Environment plumbing

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .teal
}

extension EnvironmentValues {
    var palette: ThemePalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
