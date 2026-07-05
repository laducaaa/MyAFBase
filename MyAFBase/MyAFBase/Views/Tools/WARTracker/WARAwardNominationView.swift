import SwiftUI

/// Turns a set of WAR entries into a citation-style award nomination draft.
/// Explicitly a starting point — the footer disclaimer makes clear this
/// still needs a human review pass before it goes anywhere official.
struct WARAwardNominationView: View {
    let baseID: String
    let entries: [WAREntry]

    @Environment(\.dismiss) private var dismiss
    @State private var awardName = ""
    @State private var tone: WARCitationTone = .standard
    @State private var level: WARAwardLevel = .squadron
    @State private var showCopiedToast = false
    @State private var pdfURL: URL?
    @State private var showPDFShare = false

    private var memberType: WARMemberType { WARSettingsStore.memberType }

    private var draft: String {
        WAROutputBuilder.nominationDraft(
            entries: entries,
            awardName: awardName,
            tone: tone,
            level: level,
            memberType: memberType
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Award name (optional)", text: $awardName)

                    Picker("Level", selection: $level) {
                        ForEach(WARAwardLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }

                    Picker("Tone", selection: $tone) {
                        ForEach(WARCitationTone.allCases) { tone in
                            Text(tone.title).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Nomination")
                } footer: {
                    Text("Built from \(entries.count) \(entries.count == 1 ? "entry" : "entries") in the selected date range.")
                }

                Section("Draft") {
                    ScrollView {
                        Text(draft)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 280)

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = draft
                            withAnimation { showCopiedToast = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                withAnimation { showCopiedToast = false }
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        ShareLink(item: draft) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 4)

                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF", systemImage: "doc.richtext")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }

                Section {
                    LegalDisclaimerCard(
                        text: "This draft is a starting point, not a finished citation. Review wording, remove any sensitive details, and confirm formatting against your unit's award instructions before submission."
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Award Nomination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    Text("Copied to clipboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85), in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showPDFShare) {
                if let pdfURL {
                    ActivityShareSheet(items: [pdfURL])
                }
            }
        }
    }

    private func exportPDF() {
        let subtitle = awardName.isEmpty ? level.title : "\(awardName) · \(level.title)"
        let data = WARPDFBuilder.makePDF(title: "Award Nomination Draft", subtitle: subtitle, bodyText: draft)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WARNomination-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url)
            pdfURL = url
            showPDFShare = true
        } catch {
            pdfURL = nil
        }
    }
}

#if DEBUG
#Preview {
    WARAwardNominationView(baseID: "keesler", entries: [])
}
#endif
