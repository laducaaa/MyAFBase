import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPageContent] = [
        OnboardingPageContent(
            systemImage: "building.2.fill",
            title: "Your base, organized",
            subtitle: "MyAFBase is your installation directory — everything you need for day-to-day life on base.",
            features: [
                OnboardingFeature(systemImage: "door.left.hand.open", title: "Gates & hours", detail: "See what's open, traffic, and entry notes."),
                OnboardingFeature(systemImage: "fork.knife", title: "Dining, fitness & medical", detail: "DFACs, gyms, CDC, and clinic info in one place."),
                OnboardingFeature(systemImage: "calendar", title: "Events & resources", detail: "Browse what's happening and what your base offers."),
                OnboardingFeature(systemImage: "bookmark.fill", title: "Save favorites", detail: "Bookmark gates and spots — they show up on Home.")
            ],
            gradient: [AppTheme.accent, AppTheme.accentLight]
        ),
        OnboardingPageContent(
            systemImage: "wrench.and.screwdriver.fill",
            title: "Tools built for you",
            subtitle: "Plan fitness goals, score your PFRA, and map leave around PCS — without digging through spreadsheets.",
            features: [
                OnboardingFeature(systemImage: "figure.run", title: "PFRA Score Calculator", detail: "Estimate your fitness assessment score."),
                OnboardingFeature(systemImage: "target", title: "PFRA Goal Planner", detail: "See exactly what you need to hit your goal."),
                OnboardingFeature(systemImage: "calendar.badge.clock", title: "Leave Planner", detail: "Plan leave before PCS or check trip coverage.")
            ],
            gradient: [AppTheme.brandTeal, AppTheme.brandTealLight]
        ),
        OnboardingPageContent(
            systemImage: "suitcase.fill",
            title: "Own your assignment",
            subtitle: "From arrival through PCS, track where you are in the journey and what still needs doing.",
            features: [
                OnboardingFeature(systemImage: "airplane.arrival", title: "Inbound → Stationed → Outbound", detail: "Switch phases as your assignment evolves."),
                OnboardingFeature(systemImage: "checklist", title: "PCS checklists", detail: "In-processing and out-processing tasks for your base."),
                OnboardingFeature(systemImage: "bell.badge", title: "Alerts & readiness", detail: "Base notifications and due-date reminders for fitness, dental, and more.")
            ],
            gradient: [Color(red: 0.36, green: 0.24, blue: 0.18), Color(red: 0.48, green: 0.32, blue: 0.24)]
        )
    ]

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, content in
                        OnboardingPageView(content: content)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut(duration: 0.25), value: page)

                footer
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.bottom, 28)
            }
        }
    }

    private var footer: some View {
        Button {
            if page < pages.count - 1 {
                withAnimation {
                    page += 1
                }
            } else {
                onComplete()
            }
        } label: {
            Text(page < pages.count - 1 ? "Continue" : "Choose My Base")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
    }
}

private struct OnboardingPageContent {
    let systemImage: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
    let gradient: [Color]
}

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let detail: String
}

private struct OnboardingPageView: View {
    let content: OnboardingPageContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(content.features) { feature in
                        featureRow(feature)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: content.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: content.systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(content.title)
                .font(.title.weight(.bold))

            Text(content.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(_ feature: OnboardingFeature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))

                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(AppTheme.cardShadowOpacity),
            radius: AppTheme.cardShadowRadius,
            y: AppTheme.cardShadowY
        )
    }
}

#if DEBUG
#Preview {
    OnboardingView(onComplete: {})
}
#endif
