import SwiftUI

struct MenuView: View {
    @Environment(AppState.self) private var appState
    @Environment(BookmarkStore.self) private var bookmarkStore
    @Environment(ReadinessTrackerStore.self) private var readinessTrackerStore
    @Binding var showBasePicker: Bool
    @State private var showClearBookmarksAlert = false
    @State private var remindersEnabled = ReadinessNotificationService.remindersEnabled

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    private static let generalLinks: [MenuExternalLink] = [
        MenuExternalLink(
            id: "ice",
            title: "ICE Surveys",
            systemImage: "bubble.left",
            urlString: "https://ice.disa.mil/"
        ),
        MenuExternalLink(
            id: "osi",
            title: "AF OSI",
            systemImage: "eye",
            urlString: "https://www.osi.af.mil/Submit-a-Tip/"
        ),
        MenuExternalLink(
            id: "deers",
            title: "DEERS/ID",
            systemImage: "person.crop.rectangle",
            urlString: "https://www.cac.mil/"
        ),
        MenuExternalLink(
            id: "genesis",
            title: "MyGenesis",
            systemImage: "cross.case",
            urlString: "https://my.mhsgenesis.health.mil/"
        ),
        MenuExternalLink(
            id: "tricare",
            title: "Tricare",
            systemImage: "heart.text.square",
            urlString: "https://www.tricare.mil/"
        ),
        MenuExternalLink(
            id: "myvector",
            title: "MyVector",
            systemImage: "briefcase",
            urlString: "https://myvector.us.af.mil/"
        ),
        MenuExternalLink(
            id: "vmpf",
            title: "vMPF",
            systemImage: "person.text.rectangle",
            urlString: "https://www.my.af.mil/"
        ),
        MenuExternalLink(
            id: "tmo",
            title: "Move.mil (TMO)",
            systemImage: "shippingbox",
            urlString: "https://www.move.mil/"
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    baseHeaderRow
                }

                Section("General") {
                    ForEach(Self.generalLinks) { link in
                        if let url = link.url {
                            Link(destination: url) {
                                menuLabel(title: link.title, systemImage: link.systemImage)
                            }
                        }
                    }
                }

                Section("Customize") {
                    Toggle(isOn: showWeatherToggle) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Show Weather on Home", systemImage: "cloud.sun.fill")
                                .labelStyle(AppAccentIconLabelStyle())
                            Text(weatherToggleFooter)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $remindersEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Readiness Reminders", systemImage: "bell.badge")
                                .labelStyle(AppAccentIconLabelStyle())
                            Text("Local alerts before fitness, dental, CAC, and other due dates you enter.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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

                    Button(role: .destructive) {
                        showClearBookmarksAlert = true
                    } label: {
                        Label("Clear All Bookmarks", systemImage: "bookmark.slash")
                    }
                }

                Section("Help Center") {
                    if let feedbackURL = URL(string: "mailto:feedback@myafbase.app?subject=MyAFBase%20Feedback") {
                        Link(destination: feedbackURL) {
                            menuLabel(title: "Send Feedback", systemImage: "megaphone.fill")
                        }
                    }
                }

                Section {
                    menuFooter
                        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 32, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .tint(.primary)
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
        }
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

    private var baseHeaderRow: some View {
        Button {
            showBasePicker = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.brandIconGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentBase?.name ?? "Select Base")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

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
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Change base, currently \(appState.currentBase?.name ?? "none selected")")
    }

    private func menuLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.primary)
    }

    private var menuFooter: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 40))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)

                Text("MyAFBase")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Version \(appVersion)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }
            .frame(maxWidth: .infinity)

            Divider()
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                footerNote(
                    systemImage: "icloud.fill",
                    text: "Bookmarks, assignment dates, readiness tracker, and checklists sync through iCloud when signed in."
                )

                footerNote(
                    systemImage: "globe.americas.fill",
                    text: "Base hours and alerts refresh from GitHub when you open the app or pull to refresh on Home."
                )

                footerNote(
                    systemImage: "cloud.sun.fill",
                    text: "CONUS weather from NOAA station observations. OCONUS forecasts use Open-Meteo."
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func footerNote(systemImage: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .center)
                .padding(.top, 1)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
