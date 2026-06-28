import SwiftUI

struct OnboardingView: View {
    var initialPage: Int = 0
    var onComplete: () -> Void

    @State private var page = 0
    @State private var hasAcceptedTerms = false
    @State private var hasReachedLegalEnd = false

    private let pages = OnboardingContent.pages

    private var isFinalPage: Bool {
        page >= pages.count - 1
    }

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 0) {
                OnboardingProgressBar(current: page, total: pages.count)
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, content in
                        Group {
                            if content.style == .legal {
                                OnboardingLegalPageView(
                                    content: content,
                                    hasReachedEnd: $hasReachedLegalEnd
                                )
                            } else {
                                OnboardingFeaturePageView(content: content)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.38, dampingFraction: 0.86), value: page)

                footer
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            page = min(max(initialPage, 0), pages.count - 1)
        }
        .onChange(of: page) { _, newPage in
            if newPage != pages.count - 1 {
                hasReachedLegalEnd = false
                hasAcceptedTerms = false
            }
        }
        .onChange(of: hasReachedLegalEnd) { _, reached in
            if !reached {
                hasAcceptedTerms = false
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            if isFinalPage {
                if !hasReachedLegalEnd {
                    Label {
                        Text("Scroll to the bottom to review all terms before continuing.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(AppTheme.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                OnboardingAcknowledgmentCard(
                    isOn: $hasAcceptedTerms,
                    isEnabled: hasReachedLegalEnd
                )
            }

            Button {
                if isFinalPage {
                    onComplete()
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        page += 1
                    }
                }
            } label: {
                Text(isFinalPage ? "Choose My Base" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(isFinalPage && !hasAcceptedTerms)
        }
    }
}

// MARK: - Content

private enum OnboardingPageStyle {
    case features
    case legal
}

private struct OnboardingPageContent: Identifiable {
    let id = UUID()
    let style: OnboardingPageStyle
    let eyebrow: String
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
    let tint: Color?
}

private enum OnboardingContent {
    static let pages: [OnboardingPageContent] = [
        OnboardingPageContent(
            style: .features,
            eyebrow: "Explore",
            systemImage: "building.2.fill",
            title: "Your installation,\nin one place",
            subtitle: "Gates, dining, fitness, medical, events, and more — curated for the base you select.",
            features: [
                OnboardingFeature(
                    systemImage: "door.left.hand.open",
                    title: "Gates & open now",
                    detail: "Hours, traffic notes, and what's open right now across the installation.",
                    tint: AppTheme.accent
                ),
                OnboardingFeature(
                    systemImage: "map.fill",
                    title: "Explore map",
                    detail: "Native Apple Maps with base-scoped search — no duplicate pins cluttering the map.",
                    tint: Color(red: 0.20, green: 0.55, blue: 0.42)
                ),
                OnboardingFeature(
                    systemImage: "bookmark.fill",
                    title: "Saved to Home",
                    detail: "Bookmark gates, resources, and events — they show up on your dashboard.",
                    tint: Color(red: 0.72, green: 0.52, blue: 0.12)
                )
            ],
            gradient: [AppTheme.accent, AppTheme.accentLight]
        ),
        OnboardingPageContent(
            style: .features,
            eyebrow: "Tools & widgets",
            systemImage: "square.grid.2x2.fill",
            title: "Stay ahead\nof deadlines",
            subtitle: "Fitness, leave, pay, and weather — on your phone and your Home Screen.",
            features: [
                OnboardingFeature(
                    systemImage: "figure.run",
                    title: "PFRA calculator & planner",
                    detail: "Estimate your score and see what you need to hit your target tier.",
                    tint: AppTheme.brandTeal
                ),
                OnboardingFeature(
                    systemImage: "calendar.badge.clock",
                    title: "Leave & pay calendars",
                    detail: "Plan leave around PCS and keep the next pay date visible at a glance.",
                    tint: Color(red: 0.72, green: 0.52, blue: 0.12)
                ),
                OnboardingFeature(
                    systemImage: "widget.small",
                    title: "Home Screen widgets",
                    detail: "Weather, open now, emergency contacts, pay dates, and readiness countdown.",
                    tint: AppTheme.accent
                ),
                OnboardingFeature(
                    systemImage: "mic.fill",
                    title: "Siri & Shortcuts",
                    detail: "Ask for your next pay date, next reminder, or switch bases by voice.",
                    tint: Color(red: 0.45, green: 0.35, blue: 0.82)
                )
            ],
            gradient: [AppTheme.brandTeal, AppTheme.brandTealLight]
        ),
        OnboardingPageContent(
            style: .features,
            eyebrow: "Assignment",
            systemImage: "suitcase.fill",
            title: "Own your\nassignment",
            subtitle: "From arrival through PCS — track your phase, checklists, and personal due dates.",
            features: [
                OnboardingFeature(
                    systemImage: "airplane.arrival",
                    title: "In Processing → Stationed → Out",
                    detail: "Set your phase in Menu. My Assignment shows only what's relevant.",
                    tint: Color(red: 0.48, green: 0.32, blue: 0.24)
                ),
                OnboardingFeature(
                    systemImage: "checklist",
                    title: "PCS checklists",
                    detail: "In-processing and out-processing tasks to work through at your own pace.",
                    tint: AppTheme.accent
                ),
                OnboardingFeature(
                    systemImage: "calendar.badge.clock",
                    title: "Personal reminders",
                    detail: "Track dental, fitness, evals, and more — due dates on Home and the Reminders tab.",
                    tint: Color(red: 0.78, green: 0.28, blue: 0.22)
                )
            ],
            gradient: [Color(red: 0.36, green: 0.24, blue: 0.18), Color(red: 0.48, green: 0.32, blue: 0.24)]
        ),
        OnboardingPageContent(
            style: .legal,
            eyebrow: "Before you start",
            systemImage: "checkmark.shield.fill",
            title: "Unofficial.\nTransparent.\nOn your device.",
            subtitle: "MyAFBase is a community-built reference — not a DoD or U.S. Air Force product.",
            features: LegalCopy.Section.allCases.map { section in
                OnboardingFeature(
                    systemImage: section.systemImage,
                    title: section.title,
                    detail: section.body,
                    tint: nil
                )
            },
            gradient: [AppTheme.accent, AppTheme.brandTeal]
        )
    ]
}

// MARK: - Shared chrome

private struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? AppTheme.accent : Color(.tertiarySystemFill))
                    .frame(height: 4)
                    .animation(.spring(response: 0.38, dampingFraction: 0.84), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

private struct OnboardingHeroHeader: View {
    let content: OnboardingPageContent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: content.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: content.gradient.first?.opacity(0.28) ?? .clear, radius: 12, y: 6)

                    Image(systemName: content.systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                }

                Text(content.eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent.opacity(0.10), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(content.title)
                    .font(.system(.largeTitle, design: .default, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(content.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Feature pages

private struct OnboardingFeaturePageView: View {
    let content: OnboardingPageContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingHeroHeader(content: content)

                VStack(spacing: 10) {
                    ForEach(content.features) { feature in
                        OnboardingFeatureCard(feature: feature)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct OnboardingFeatureCard: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill((feature.tint ?? AppTheme.accent).opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: feature.systemImage)
                    .font(.body.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(feature.tint ?? AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))

                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
        }
    }
}

// MARK: - Legal page

private struct OnboardingLegalPageView: View {
    let content: OnboardingPageContent
    @Binding var hasReachedEnd: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingHeroHeader(content: content)

                VStack(spacing: 0) {
                    ForEach(Array(content.features.enumerated()), id: \.element.id) { index, feature in
                        if index > 0 {
                            Divider()
                                .padding(.leading, 54)
                        }
                        OnboardingLegalRow(feature: feature)
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                }

                Label {
                    Text("Always verify hours, gate access, and emergency numbers with official installation sources.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)

                Color.clear
                    .frame(height: 1)
                    .onAppear { hasReachedEnd = true }
                    .onDisappear { hasReachedEnd = false }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct OnboardingLegalRow: View {
    let feature: OnboardingFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))

                Text(feature.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct OnboardingAcknowledgmentCard: View {
    @Binding var isOn: Bool
    var isEnabled: Bool = true

    var body: some View {
        Button {
            guard isEnabled else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? AppTheme.accent : Color(.tertiaryLabel))
                    .symbolEffect(.bounce, value: isOn)

                Text(LegalCopy.onboardingAcknowledgment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .strokeBorder(
                        isOn ? AppTheme.accent.opacity(0.35) : Color.primary.opacity(0.05),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .accessibilityLabel(LegalCopy.onboardingAcknowledgment)
        .accessibilityValue(isOn ? "Accepted" : isEnabled ? "Not accepted" : "Review terms by scrolling to the bottom first")
    }
}

// MARK: - Previews

#if DEBUG
private struct OnboardingPreviewHost: View {
    var initialPage: Int = 0

    var body: some View {
        OnboardingView(initialPage: initialPage, onComplete: {})
    }
}

#Preview("Full flow") {
    OnboardingPreviewHost()
}

#Preview("1 – Explore") {
    OnboardingPreviewHost(initialPage: 0)
}

#Preview("2 – Tools & widgets") {
    OnboardingPreviewHost(initialPage: 1)
}

#Preview("3 – Assignment") {
    OnboardingPreviewHost(initialPage: 2)
}

#Preview("4 – Legal") {
    OnboardingPreviewHost(initialPage: 3)
}

#Preview("4 – Legal (accepted)") {
    OnboardingLegalAcceptedPreview()
}

#Preview("Acknowledgment – enabled") {
    OnboardingAcknowledgmentPreview(isEnabled: true, isOn: false)
}

#Preview("Acknowledgment – locked") {
    OnboardingAcknowledgmentPreview(isEnabled: false, isOn: false)
}

private struct OnboardingAcknowledgmentPreview: View {
    @State var isEnabled: Bool
    @State var isOn: Bool

    var body: some View {
        ZStack {
            AppScreenBackground()
            OnboardingAcknowledgmentCard(isOn: $isOn, isEnabled: isEnabled)
                .padding()
        }
    }
}

private struct OnboardingLegalAcceptedPreview: View {
    @State private var accepted = true

    var body: some View {
        ZStack {
            AppScreenBackground()
            VStack {
                Spacer()
                OnboardingAcknowledgmentCard(isOn: $accepted, isEnabled: true)
                    .padding()
                Spacer()
            }
        }
    }
}
#endif
