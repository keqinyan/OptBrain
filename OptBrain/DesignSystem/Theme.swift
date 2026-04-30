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
    case sky
    case indigo
    case lavender
    case rose
    case crimson
    case amber
    case forest
    case slate
    case graphite

    var id: String { rawValue }

    var displayKey: String {
        switch self {
        case .teal:     return "theme.teal"
        case .sky:      return "theme.sky"
        case .indigo:   return "theme.indigo"
        case .lavender: return "theme.lavender"
        case .rose:     return "theme.rose"
        case .crimson:  return "theme.crimson"
        case .amber:    return "theme.amber"
        case .forest:   return "theme.forest"
        case .slate:    return "theme.slate"
        case .graphite: return "theme.graphite"
        }
    }

    /// Light + dark sRGB tuples (red, green, blue).
    private var components: (light: (Double, Double, Double), dark: (Double, Double, Double)) {
        switch self {
        case .teal:     return ((0.165, 0.616, 0.561), (0.310, 0.741, 0.667))
        case .sky:      return ((0.024, 0.588, 0.780), (0.310, 0.714, 0.847))
        case .indigo:   return ((0.231, 0.353, 0.627), (0.435, 0.553, 0.808))
        case .lavender: return ((0.435, 0.337, 0.580), (0.624, 0.522, 0.765))
        case .rose:     return ((0.769, 0.227, 0.318), (0.886, 0.435, 0.510))
        case .crimson:  return ((0.545, 0.110, 0.235), (0.741, 0.275, 0.388))
        case .amber:    return ((0.890, 0.561, 0.165), (0.965, 0.694, 0.310))
        case .forest:   return ((0.247, 0.416, 0.302), (0.420, 0.643, 0.475))
        case .slate:    return ((0.290, 0.361, 0.416), (0.518, 0.604, 0.671))
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
