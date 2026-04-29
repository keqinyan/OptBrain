import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.palette) private var palette
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(symbol: "brain.head.profile",
              titleKey: "onboarding.welcome.title",
              bodyKey: "onboarding.welcome.body"),
        .init(symbol: "clock.arrow.circlepath",
              titleKey: "onboarding.howItWorks.title",
              bodyKey: "onboarding.howItWorks.body"),
        .init(symbol: "lock.shield",
              titleKey: "onboarding.privacy.title",
              bodyKey: "onboarding.privacy.body"),
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i])
                        .tag(i)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "onboarding.cta.continue" : "onboarding.cta.start")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("onboarding.disclaimer")
                    .font(.footnote)
                    .foregroundStyle(Theme.onSurfaceMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 32)
            Image(systemName: page.symbol)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(palette.accent)
            Text(LocalizedStringKey(page.titleKey))
                .font(.optDashboardTitle)
                .multilineTextAlignment(.center)
            Text(LocalizedStringKey(page.bodyKey))
                .font(.body)
                .foregroundStyle(Theme.onSurfaceMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let titleKey: String
    let bodyKey: String
}
