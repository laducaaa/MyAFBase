import SwiftUI

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @FocusState private var isMessageFocused: Bool
    @State private var category: FeedbackCategory = .general
    @State private var message = ""
    @State private var contactEmail = ""
    @State private var wantsReply = false
    @State private var contactEmailConsent = false
    @State private var isSubmitting = false
    @State private var didSucceed = false
    @State private var errorMessage: String?
    @State private var showLegalPrivacySheet = false

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var messageCount: Int {
        trimmedMessage.count
    }

    private var canSubmit: Bool {
        FeedbackConfig.endpoint != nil &&
            !isSubmitting &&
            !didSucceed &&
            messageCount >= FeedbackConfig.minimumMessageLength
    }

    var body: some View {
        NavigationStack {
            Group {
                if didSucceed {
                    successView
                } else {
                    formScrollView
                }
            }
            .appScreenBackground()
            .navigationTitle(didSucceed ? "" : "Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if didSucceed {
                        EmptyView()
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .interactiveDismissDisabled(isSubmitting)
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .sheet(isPresented: $showLegalPrivacySheet) {
            LegalPrivacySheet()
        }
        .onChange(of: wantsReply) { _, enabled in
            if !enabled {
                contactEmailConsent = false
                contactEmail = ""
            }
        }
    }

    private var formScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                introHeader

                #if DEBUG
                if FeedbackConfig.endpoint == nil {
                    developerSetupCard
                }
                #endif

                categorySection
                privacyNoticeSection
                messageSection
                replySection

                if let errorMessage {
                    errorBanner(errorMessage)
                }

                sendButton
            }
            .padding()
            .padding(.bottom, 8)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var introHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "megaphone.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Thanks for sharing")
                        .font(.headline)

                    Text("Your feedback helps make MyAFBase better for the community. We genuinely appreciate you taking the time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCardStyle()
    }

    private var privacyNoticeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            LegalDisclaimerCard(
                text: LegalCopy.feedbackPII,
                style: .warning,
                systemImage: "exclamationmark.shield"
            )

            Button {
                showLegalPrivacySheet = true
            } label: {
                Label("Read privacy & data handling notice", systemImage: "doc.text")
                    .font(.caption.weight(.medium))
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's this about?")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FeedbackCategory.allCases) { option in
                    FeedbackCategoryChip(
                        category: option,
                        isSelected: category == option
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            category = option
                        }
                    }
                }
            }
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your message")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(messageCountLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(messageCount >= FeedbackConfig.minimumMessageLength ? .green : .secondary)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isMessageFocused ? AppTheme.accent.opacity(0.45) : Color.primary.opacity(0.06),
                                lineWidth: isMessageFocused ? 1.5 : 1
                            )
                    }

                TextEditor(text: $message)
                    .focused($isMessageFocused)
                    .frame(minHeight: 150)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(.clear)

                if message.isEmpty {
                    Text(category.messagePlaceholder)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }

            Text("Please include enough detail that we can understand the issue or idea.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle()
    }

    private var messageCountLabel: String {
        if messageCount >= FeedbackConfig.minimumMessageLength {
            return "Ready to send"
        }
        let remaining = FeedbackConfig.minimumMessageLength - messageCount
        return remaining == 1 ? "1 more character" : "\(remaining) more characters"
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $wantsReply.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("I'd like a reply")
                        .font(.subheadline.weight(.medium))
                    Text("Optional — only if you want us to follow up.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if wantsReply {
                Toggle(isOn: $contactEmailConsent) {
                    Text("I agree to share my email with the MyAFBase team via our private feedback channel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextField("Email address", text: $contactEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .disabled(!contactEmailConsent)
            }
        }
        .appCardStyle()
    }

    private var sendButton: some View {
        Button {
            isMessageFocused = false
            Task { await submitFeedback() }
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text(isSubmitting ? "Sending…" : "Send Feedback")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                canSubmit ? AppTheme.accent : AppTheme.accent.opacity(0.35),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .accessibilityLabel(isSubmitting ? "Sending feedback" : "Send feedback")
    }

    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 88, height: 88)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: didSucceed)
                }

                VStack(spacing: 8) {
                    Text("Thanks — we got it!")
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(successSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
            }
            .appCardStyle(padding: 28)
            .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding()
        }
    }

    private var successSubtitle: String {
        if wantsReply, !contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Your \(category.chipTitle.lowercased()) feedback was sent to the MyAFBase team. If we need anything else, we'll reach out by email."
        }
        return "Your \(category.chipTitle.lowercased()) feedback was sent to the MyAFBase team. We read every message and use it to make the app better."
    }

    #if DEBUG
    private var developerSetupCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Developer: feedback not configured", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            Text("Set FeedbackConfig.endpoint after deploying scripts/feedback-worker.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .appCardStyle(background: Color.orange.opacity(0.08))
    }
    #endif

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @MainActor
    private func submitFeedback() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await FeedbackService.submit(
                category: category,
                message: message,
                contactEmail: wantsReply ? contactEmail : nil,
                contactEmailConsent: wantsReply && contactEmailConsent,
                baseID: appState.currentBase?.id,
                baseName: appState.currentBase?.name
            )
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                didSucceed = true
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct FeedbackCategoryChip: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(category.chipTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.accent)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(category.title)
    }
}
