import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

struct MetricTile: View {
    @Environment(\.palette) private var palette
    let labelKey: String
    let value: String
    let symbol: String?

    init(labelKey: String, value: String, symbol: String? = nil) {
        self.labelKey = labelKey
        self.value = value
        self.symbol = symbol
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol).foregroundStyle(palette.accent) }
                Text(LocalizedStringKey(labelKey))
                    .font(.optMetricLabel)
                    .foregroundStyle(Theme.onSurfaceMuted)
            }
            Text(value)
                .font(.optMetricValue)
                .foregroundStyle(Theme.onSurface)
                .monospacedDigit()
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(palette.accent.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
            .foregroundStyle(Theme.onSurface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.divider, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
