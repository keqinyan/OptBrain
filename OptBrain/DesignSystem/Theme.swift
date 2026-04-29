import SwiftUI

/// Calm, science-inspired palette. Reads naturally in dark mode.
enum Theme {
    static let accent = Color("AccentColor", bundle: nil) // Asset catalog overrides if present
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
    static let optMetricValue: Font = .system(.title, design: .rounded, weight: .semibold)
    static let optMetricLabel: Font = .system(.caption, design: .rounded, weight: .medium)
}
