import SwiftUI

struct OnboardingView: View {
    var initialPage: Int = 0
    var onComplete: () -> Void

    @State private var page = 0
    @State private var hasAcceptedTerms = false
    @State private var hasReachedLegalEnd = false

    private let pages = OnboardingContent.pages

    @Environment(\.colorScheme) private var colorScheme

    private var onboardingCanvas: Color {
        colorScheme == .dark ? .black : .white
    }

    private var onboardingInk: Color {
        colorScheme == .dark ? .white : .black
    }

    private var isFinalPage: Bool {
        page >= pages.count - 1
    }

    var body: some View {
        ZStack {
            onboardingCanvas.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, content in
                        Group {
                            if content.style == .legal {
                                OnboardingLegalPageView(
                                    content: content,
                                    isActive: page == index,
                                    hasReachedEnd: $hasReachedLegalEnd,
                                    hasAcceptedTerms: $hasAcceptedTerms
                                )
                            } else {
                                OnboardingFeaturePageView(
                                    content: content,
                                    isActive: page == index
                                )
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(OnboardingMotion.pageSpring, value: page)
                .ignoresSafeArea(edges: .top)

                footer
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
        Button {
            if isFinalPage {
                onComplete()
            } else {
                withAnimation(OnboardingMotion.pageSpring) {
                    page += 1
                }
            }
        } label: {
            Text(isFinalPage ? "Choose My Base" : "Continue")
                .font(.headline)
                .foregroundStyle(onboardingCanvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(onboardingInk)
        .disabled(isFinalPage && !hasAcceptedTerms)
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }
}

// MARK: - Motion

private enum OnboardingMotion {
    static let pageSpring = Animation.spring(response: 0.52, dampingFraction: 0.86)
    static let heroSpring = Animation.spring(response: 0.62, dampingFraction: 0.88)

    static func stagger(_ index: Int, base: Double = 0.14) -> Animation {
        pageSpring.delay(base + Double(index) * 0.07)
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
    let heroImageName: String?
    let eyebrow: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeature]
}

private struct OnboardingFeature: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let detail: String
}

private enum OnboardingContent {
    static let pages: [OnboardingPageContent] = [
        OnboardingPageContent(
            style: .features,
            heroImageName: "OnboardingHero1",
            eyebrow: "Explore",
            title: "Your installation,\nmapped & searchable",
            subtitle: "Browse gates, dining, fitness, events, and base services — as a list or on Apple Maps.",
            features: [
                OnboardingFeature(
                    systemImage: "list.bullet.rectangle",
                    title: "List & map modes",
                    detail: "Switch between categorized lists and a base-scoped map with clean POI search."
                ),
                OnboardingFeature(
                    systemImage: "clock.badge.checkmark",
                    title: "Open now filter",
                    detail: "See what's open across the installation right now — gates, dining, fitness, and more."
                ),
                OnboardingFeature(
                    systemImage: "calendar",
                    title: "Events & resources",
                    detail: "Holidays, community activities, and installation services in one Explore tab."
                ),
                OnboardingFeature(
                    systemImage: "bookmark.fill",
                    title: "Saved to Home",
                    detail: "Bookmark gates, resources, and events — they show up on your dashboard."
                )
            ]
        ),
        OnboardingPageContent(
            style: .features,
            heroImageName: "OnboardingHero2",
            eyebrow: "Tools & widgets",
            title: "Plan fitness,\nleave & pay",
            subtitle: "Built-in planners, offline AFI search, and Home Screen widgets keep you ahead of deadlines.",
            features: [
                OnboardingFeature(
                    systemImage: "text.magnifyingglass",
                    title: "Essential AFI Search",
                    detail: "Search key publications offline from Home — citations open the official PDFs."
                ),
                OnboardingFeature(
                    systemImage: "figure.strengthtraining.functional",
                    title: "PFRA calculator & planner",
                    detail: "Estimate your score, plan toward a target tier, and track progress at a glance."
                ),
                OnboardingFeature(
                    systemImage: "calendar.badge.clock",
                    title: "Leave & pay planners",
                    detail: "Multi-trip leave, balance projection, PCS caps, and pay-gap warnings in one place."
                ),
                OnboardingFeature(
                    systemImage: "widget.small",
                    title: "Widgets & Siri",
                    detail: "Weather, pay dates, open now, readiness, and emergency contacts — plus voice shortcuts."
                )
            ]
        ),
        OnboardingPageContent(
            style: .features,
            heroImageName: "OnboardingHero3",
            eyebrow: "Assignment",
            title: "Track your\nassignment phase",
            subtitle: "From arrival through PCS — key dates, readiness items, and checklists tailored to where you are.",
            features: [
                OnboardingFeature(
                    systemImage: "airplane.arrival",
                    title: "Phase-aware views",
                    detail: "Set In Processing, Stationed, or Out in Menu — My Assignment shows only what's relevant."
                ),
                OnboardingFeature(
                    systemImage: "calendar.badge.clock",
                    title: "Key dates & countdowns",
                    detail: "Report, RNLTD, DEROS, and more — tap to edit with days-left badges."
                ),
                OnboardingFeature(
                    systemImage: "checklist",
                    title: "Readiness & PCS checklists",
                    detail: "Dental, fitness, evals, and in/out-processing tasks with due dates on Home and Reminders."
                )
            ]
        ),
        OnboardingPageContent(
            style: .legal,
            heroImageName: nil,
            eyebrow: "Before you start",
            title: "Unofficial.\nTransparent.\nOn your device.",
            subtitle: "MyAFBase is a community-built reference — not affiliated with the DoD or U.S. Air Force.",
            features: LegalCopy.Section.allCases.map { section in
                OnboardingFeature(
                    systemImage: section.systemImage,
                    title: section.title,
                    detail: section.body
                )
            }
        )
    ]
}

// MARK: - Hero image

private struct OnboardingHeroImage: View {
    let imageName: String
    let height: CGFloat
    var isRevealed: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var canvas: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        ZStack(alignment: .top) {
            canvas

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .scaleEffect(isRevealed ? 1 : 1.05)
                .opacity(isRevealed ? 1 : 0.85)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.52),
                            .init(color: .black.opacity(0.92), location: 0.68),
                            .init(color: .black.opacity(0.55), location: 0.82),
                            .init(color: .black.opacity(0.15), location: 0.93),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .animation(OnboardingMotion.heroSpring, value: isRevealed)
    }
}

private struct OnboardingMonochromeHeader: View {
    let content: OnboardingPageContent
    var compact: Bool = false
    var isRevealed: Bool = true
    var headerIcon: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inkSecondary: Color {
        ink.opacity(0.62)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            if let headerIcon {
                Image(systemName: headerIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(ink)
                    .opacity(isRevealed ? 1 : 0)
                    .offset(y: isRevealed ? 0 : 8)
                    .animation(OnboardingMotion.stagger(0, base: 0.08), value: isRevealed)
            }

            Text(content.eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(inkSecondary)
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 10)
                .animation(OnboardingMotion.stagger(headerIcon == nil ? 0 : 1, base: 0.08), value: isRevealed)

            Text(content.title)
                .font(.system(compact ? .title : .largeTitle, design: .default, weight: .bold))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 14)
                .animation(OnboardingMotion.stagger(headerIcon == nil ? 1 : 2, base: 0.08), value: isRevealed)

            Text(content.subtitle)
                .font(compact ? .callout : .body)
                .foregroundStyle(inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 12)
                .animation(OnboardingMotion.stagger(headerIcon == nil ? 2 : 3, base: 0.08), value: isRevealed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Legal page

private struct OnboardingLegalPageView: View {
    let content: OnboardingPageContent
    let isActive: Bool
    @Binding var hasReachedEnd: Bool
    @Binding var hasAcceptedTerms: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false

    private var canvas: Color {
        colorScheme == .dark ? .black : .white
    }

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inkSecondary: Color {
        ink.opacity(0.62)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                OnboardingMonochromeHeader(
                    content: content,
                    compact: true,
                    isRevealed: isRevealed,
                    headerIcon: "checkmark.shield"
                )
                .safeAreaPadding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(content.features.enumerated()), id: \.element.id) { index, feature in
                        if index > 0 {
                            Divider()
                                .opacity(colorScheme == .dark ? 0.22 : 0.14)
                        }
                        OnboardingMonochromeFeatureRow(
                            feature: feature,
                            compact: true,
                            isRevealed: isRevealed,
                            index: index + 4
                        )
                    }
                }

                Text("Always verify hours, gate access, and emergency numbers with official installation sources.")
                    .font(.caption)
                    .foregroundStyle(inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .opacity(isRevealed ? 1 : 0)
                    .animation(OnboardingMotion.stagger(9, base: 0.1), value: isRevealed)

                Color.clear
                    .frame(height: 1)
                    .onAppear { hasReachedEnd = true }
                    .onDisappear { hasReachedEnd = false }

                OnboardingAcknowledgmentCard(
                    isOn: $hasAcceptedTerms,
                    isEnabled: hasReachedEnd
                )
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 12)
                .animation(OnboardingMotion.stagger(10, base: 0.12), value: isRevealed)
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(canvas)
        .onAppear { triggerRevealIfNeeded() }
        .onChange(of: isActive) { _, active in
            if active {
                triggerRevealIfNeeded()
            } else {
                isRevealed = false
            }
        }
    }

    private func triggerRevealIfNeeded() {
        guard isActive else { return }
        isRevealed = false
        withAnimation(OnboardingMotion.pageSpring) {
            isRevealed = true
        }
    }
}

private struct OnboardingAcknowledgmentCard: View {
    @Binding var isOn: Bool
    var isEnabled: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inkSecondary: Color {
        ink.opacity(0.62)
    }

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
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isOn ? ink : ink.opacity(0.35))
                    .symbolEffect(.bounce, value: isOn)

                Text(LegalCopy.onboardingAcknowledgment)
                    .font(.caption)
                    .foregroundStyle(inkSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
        .accessibilityLabel(LegalCopy.onboardingAcknowledgment)
        .accessibilityValue(isOn ? "Accepted" : isEnabled ? "Not accepted" : "Review terms by scrolling to the bottom first")
    }
}

private struct OnboardingFeaturePageView: View {
    let content: OnboardingPageContent
    let isActive: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false

    private var canvas: Color {
        colorScheme == .dark ? .black : .white
    }

    private var isCompact: Bool {
        content.features.count >= 4
    }

    private func heroHeight(totalHeight: CGFloat, width: CGFloat) -> CGFloat {
        let ratio: CGFloat = isCompact ? 0.30 : 0.34
        let scaled = totalHeight * ratio
        return min(max(scaled, 165), width * 0.56)
    }

    var body: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top
            let layoutHeight = geometry.size.height - topInset
            let heroH = heroHeight(totalHeight: layoutHeight, width: geometry.size.width)
            let fullHeroH = heroH + topInset

            VStack(spacing: 0) {
                if let heroImageName = content.heroImageName {
                    OnboardingHeroImage(
                        imageName: heroImageName,
                        height: fullHeroH,
                        isRevealed: isRevealed
                    )
                }

                VStack(alignment: .leading, spacing: isCompact ? 10 : 14) {
                    OnboardingMonochromeHeader(
                        content: content,
                        compact: isCompact,
                        isRevealed: isRevealed
                    )

                    VStack(spacing: 0) {
                        ForEach(Array(content.features.enumerated()), id: \.element.id) { index, feature in
                            if index > 0 {
                                Divider()
                                    .opacity(colorScheme == .dark ? 0.22 : 0.14)
                            }
                            OnboardingMonochromeFeatureRow(
                                feature: feature,
                                compact: isCompact,
                                isRevealed: isRevealed,
                                index: index
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 2)
                .background(canvas)

                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .background(canvas)
        .onAppear { triggerRevealIfNeeded() }
        .onChange(of: isActive) { _, active in
            if active {
                triggerRevealIfNeeded()
            } else {
                isRevealed = false
            }
        }
    }

    private func triggerRevealIfNeeded() {
        guard isActive else { return }
        isRevealed = false
        withAnimation(OnboardingMotion.pageSpring) {
            isRevealed = true
        }
    }
}

private struct OnboardingMonochromeFeatureRow: View {
    let feature: OnboardingFeature
    var compact: Bool = false
    var isRevealed: Bool = true
    var index: Int = 0

    @Environment(\.colorScheme) private var colorScheme

    private var ink: Color {
        colorScheme == .dark ? .white : .black
    }

    private var inkSecondary: Color {
        ink.opacity(0.62)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feature.systemImage)
                .font(compact ? .subheadline.weight(.semibold) : .body.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(ink)
                .frame(width: 24, alignment: .center)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(ink)

                Text(feature.detail)
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, compact ? 7 : 9)
        .opacity(isRevealed ? 1 : 0)
        .offset(x: isRevealed ? 0 : 18)
        .animation(OnboardingMotion.stagger(index + 3, base: 0.1), value: isRevealed)
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
            Color.black.ignoresSafeArea()
            OnboardingAcknowledgmentCard(isOn: $isOn, isEnabled: isEnabled)
                .padding()
        }
    }
}

private struct OnboardingLegalAcceptedPreview: View {
    @State private var accepted = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
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
