import SwiftUI

struct MenuView: View {
    @Environment(AppState.self) private var appState
    @Environment(BookmarkStore.self) private var bookmarkStore
    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @Environment(AssignmentProfileStore.self) private var assignmentProfileStore
    @Binding var showBasePicker: Bool
    @State private var showClearBookmarksAlert = false
    @State private var showWhatsNewSheet = false
    @State private var showFeedbackSheet = false
    @State private var showLegalPrivacySheet = false
    @State private var remindersEnabled = ReadinessNotificationService.remindersEnabled

    private var appVersion: String { AppReleaseNotes.appVersion }

    private static let generalLinks: [MenuExternalLink] = [
        MenuExternalLink(id: "ice", title: "ICE Surveys", systemImage: "bubble.left", urlString: "https://ice.disa.mil/"),
        MenuExternalLink(id: "osi", title: "AF OSI", systemImage: "eye", urlString: "https://www.osi.af.mil/Submit-a-Tip/"),
        MenuExternalLink(id: "deers", title: "DEERS/ID", systemImage: "person.crop.rectangle", urlString: "https://www.cac.mil/"),
        MenuExternalLink(id: "genesis", title: "MyGenesis", systemImage: "cross.case", urlString: "https://my.mhsgenesis.health.mil/"),
        MenuExternalLink(id: "tricare", title: "Tricare", systemImage: "heart.text.square", urlString: "https://www.tricare.mil/"),
        MenuExternalLink(id: "myvector", title: "MyVector", systemImage: "briefcase", urlString: "https://myvector.us.af.mil/"),
        MenuExternalLink(id: "vmpf", title: "vMPF", systemImage: "person.text.rectangle", urlString: "https://www.my.af.mil/"),
        MenuExternalLink(id: "tmo", title: "Move.mil (TMO)", systemImage: "shippingbox", urlString: "https://www.move.mil/")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    installationSection
                    quickLinksSection
                    preferencesSection
                    supportSection
                    legalSection
                    aboutSection
                }
                .padding(AppTheme.screenPadding)
                .padding(.bottom, 8)
            }
            .appScreenBackground()
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Bookmarks?", isPresented: $showClearBookmarksAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    bookmarkStore.clearAllBookmarks()
                }
            } message: {
                Text("This will remove all saved gates, resources, and events across every installation on this device. This cannot be undone.")
            }
            .sheet(isPresented: $showWhatsNewSheet) {
                WhatsNewSheet()
            }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet()
            }
            .sheet(isPresented: $showLegalPrivacySheet) {
                LegalPrivacySheet()
            }
        }
    }

    // MARK: - Installation

    private var installationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Installation")

            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showBasePicker = true
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.currentBase?.name ?? "Select Base")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            if let base = appState.currentBase {
                                Text("\(base.wing) · \(base.location)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let updated = base.formattedDataUpdated {
                                    Text("Data updated \(updated)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            } else {
                                Text("Tap to choose your installation")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change base, currently \(appState.currentBase?.name ?? "none selected")")

                if let base = appState.currentBase {
                    Divider()

                    MenuAssignmentPhaseRow(baseID: base.id)
                }
            }
            .appCardStyle()
        }
    }

    // MARK: - Quick Links

    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Links")

            VStack(spacing: 0) {
                ForEach(Array(Self.generalLinks.enumerated()), id: \.element.id) { index, link in
                    if let url = link.url {
                        Link(destination: url) {
                            MenuLinkRow(title: link.title, systemImage: link.systemImage)
                        }
                        .buttonStyle(.plain)

                        if index < Self.generalLinks.count - 1 {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Preferences")

            VStack(alignment: .leading, spacing: 16) {
                MenuToggleRow(
                    title: "Show Weather on Home",
                    subtitle: weatherToggleFooter,
                    systemImage: "cloud.sun.fill",
                    isOn: showWeatherToggle
                )

                Divider()

                MenuToggleRow(
                    title: "Readiness Reminders",
                    subtitle: "Local alerts before fitness, dental, CAC, and other due dates you enter.",
                    systemImage: "bell.badge",
                    isOn: $remindersEnabled
                )
                .onChange(of: remindersEnabled) { _, enabled in
                    Task {
                        let active = await ReadinessNotificationService.setRemindersEnabled(enabled)
                        remindersEnabled = active
                        if active {
                            await ReadinessNotificationService.rescheduleAll(
                                readinessTrackerStore.allTrackers()
                            ) { baseID in
                                appState.currentBase?.id == baseID
                                    ? (appState.currentBase?.name ?? "your base")
                                    : baseID
                            }
                        }
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showClearBookmarksAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bookmark.slash")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text("Clear All Bookmarks")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)

                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
            .appCardStyle()
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Support")

            Button {
                showFeedbackSheet = true
            } label: {
                MenuLinkRow(title: "Send Feedback", systemImage: "megaphone.fill", showsExternalIndicator: false)
            }
            .buttonStyle(.plain)
            .appCardStyle(padding: 14)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Legal & Privacy")

            LegalDisclaimerCard(
                text: LegalCopy.nonAffiliationShort,
                style: .compact,
                systemImage: "building.columns"
            )
            .padding(.horizontal, 4)

            Button {
                showLegalPrivacySheet = true
            } label: {
                MenuLinkRow(title: "Legal & Privacy Notice", systemImage: "doc.text", showsExternalIndicator: false)
            }
            .buttonStyle(.plain)
            .appCardStyle(padding: 14)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Button {
            showWhatsNewSheet = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MyAFBase")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("What's new in version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("v\(appVersion)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemFill), in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .appCardStyle()
        .accessibilityLabel("What's new in version \(appVersion)")
    }

    private var showWeatherToggle: Binding<Bool> {
        Binding(
            get: { appState.showCONUSWeatherInHero },
            set: { appState.setShowCONUSWeatherInHero($0) }
        )
    }

    private var weatherToggleFooter: String {
        if appState.currentBaseRegion == .oconus {
            return "Weather is hidden for OCONUS installations."
        }
        return "Show current conditions in the Home hero for CONUS bases."
    }
}

// MARK: - Row Components

private struct MenuLinkRow: View {
    let title: String
    let systemImage: String
    var showsExternalIndicator: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Image(systemName: showsExternalIndicator ? "arrow.up.right" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, showsExternalIndicator ? 14 : 0)
        .padding(.vertical, showsExternalIndicator ? 12 : 0)
        .contentShape(Rectangle())
    }
}

private struct MenuToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

private struct MenuExternalLink: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let urlString: String

    var url: URL? {
        URL(string: urlString)
    }
}
