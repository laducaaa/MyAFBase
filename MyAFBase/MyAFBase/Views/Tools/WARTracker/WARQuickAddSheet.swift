import SwiftUI
import SwiftData

/// Fast accomplishment logger — card-based layout matching the rest of the app.
struct WARQuickAddSheet: View {
    let baseID: String
    var entryToEdit: WAREntry?
    var defaultDate: Date = Date()
    var initialText: String = ""
    var locksDate: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(WARTrackerStore.self) private var store
    @FocusState private var textFocused: Bool

    @State private var date: Date
    @State private var text: String
    @State private var category: WARCategory
    @State private var performanceFactor: WARPerformanceFactor?
    @State private var tags: [String]
    @State private var tagDraft = ""
    @State private var impact: String
    @State private var beneficiary: String
    @State private var hoursText: String
    @State private var showDetails = false

    init(
        baseID: String,
        entryToEdit: WAREntry? = nil,
        defaultDate: Date = Date(),
        initialText: String = "",
        locksDate: Bool = false
    ) {
        self.baseID = baseID
        self.entryToEdit = entryToEdit
        self.defaultDate = defaultDate
        self.initialText = initialText
        self.locksDate = locksDate

        _date = State(initialValue: entryToEdit?.date ?? defaultDate)
        _text = State(initialValue: entryToEdit?.text ?? initialText)
        _category = State(initialValue: entryToEdit?.category ?? .job)
        _performanceFactor = State(initialValue: entryToEdit?.performanceFactor)
        _tags = State(initialValue: entryToEdit?.tags ?? [])
        _impact = State(initialValue: entryToEdit?.impact ?? "")
        _beneficiary = State(initialValue: entryToEdit?.beneficiary ?? "")
        _hoursText = State(initialValue: entryToEdit?.hours.map { String($0) } ?? "")
        _showDetails = State(initialValue: entryToEdit != nil && (
            entryToEdit?.performanceFactor != nil
                || !(entryToEdit?.tags.isEmpty ?? true)
                || entryToEdit?.impact != nil
                || entryToEdit?.beneficiary != nil
                || entryToEdit?.hours != nil
        ))
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { !trimmedText.isEmpty }
    private var isEditing: Bool { entryToEdit != nil }

    private var flaggedForPII: Bool {
        WARPIIScanner.containsLikelyPII(trimmedText)
            || WARPIIScanner.containsLikelyPII(impact)
            || WARPIIScanner.containsLikelyPII(beneficiary)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                    headerCard
                    accomplishmentCard
                    categoryCard

                    if flaggedForPII {
                        piiWarningCard
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    detailsCard
                }
                .padding()
                .padding(.bottom, 8)
                .animation(WARMotion.spring, value: flaggedForPII)
                .animation(WARMotion.spring, value: showDetails)
            }
            .scrollDismissesKeyboard(.interactively)
            .appScreenBackground()
            .navigationTitle(isEditing ? "Edit Entry" : "Log Accomplishment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            if let entryToEdit {
                                store.delete(entryToEdit)
                            }
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Delete entry")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if canSave {
                    saveButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(WARMotion.spring, value: canSave)
            .onAppear {
                if !isEditing {
                    textFocused = true
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(AppTheme.cardCornerRadius)
    }

    // MARK: - Cards

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(
                systemImage: isEditing ? "pencil.circle.fill" : "text.badge.star",
                tint: AppTheme.brandSecondary,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                if locksDate && !isEditing {
                    Text(WARDateMath.dayLabel(for: date))
                        .font(.headline)
                } else {
                    Text(isEditing ? "Update your entry" : "Quick log")
                        .font(.headline)

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .font(.subheadline)
                    .tint(AppTheme.accent)
                }

                Text(isEditing ? date.formatted(date: .abbreviated, time: .omitted) : "What did you get done?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCardStyle()
    }

    private var accomplishmentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accomplishment")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Led project X, mentored 3 Airmen, volunteered at…", text: $text, axis: .vertical)
                .lineLimit(4...10)
                .focused($textFocused)
                .font(.body)
                .onSubmit {
                    if canSave { save() }
                }

            Text(LegalCopy.warTrackerPIIReminder)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .appCardStyle()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            WARCategoryChipRow(selection: $category)
        }
        .appCardStyle()
    }

    private var piiWarningCard: some View {
        Label {
            Text("This may contain sensitive details. Review before exporting.")
                .font(.footnote)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(AppTheme.warning)
        .appCardStyle(background: AppTheme.warning.opacity(0.08))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(WARMotion.spring) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Text("More details")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showDetails ? 90 : 0))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if showDetails {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    performanceFactorPicker

                    tagsField
                    impactField
                    beneficiaryField
                    hoursField
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .appCardStyle()
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(isEditing ? "Save Changes" : "Log Accomplishment")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Detail fields

    private var performanceFactorPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Performance factor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Performance factor", selection: $performanceFactor) {
                Text("None").tag(WARPerformanceFactor?.none)
                ForEach(WARPerformanceFactor.allCases) { factor in
                    Text(factor.title).tag(WARPerformanceFactor?.some(factor))
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.accent)
        }
    }

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                TextField("flightline, volunteer…", text: $tagDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(addDraftTag)

                Button("Add", action: addDraftTag)
                    .font(.subheadline.weight(.semibold))
                    .disabled(tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !tags.isEmpty {
                AFISearchChipLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        WARTagChip(title: "#\(tag)") {
                            withAnimation(WARMotion.spring) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }

            let suggestions = store.suggestedTags(for: baseID).filter { !tags.contains($0) }
            if !suggestions.isEmpty {
                AFISearchChipLayout(spacing: 6) {
                    ForEach(suggestions, id: \.self) { tag in
                        Button {
                            withAnimation(WARMotion.spring) {
                                tags.append(tag)
                            }
                        } label: {
                            Text("#\(tag)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var impactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Impact")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Result or outcome (optional)", text: $impact, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var beneficiaryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Who benefited")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Unit, team, community (optional)", text: $beneficiary)
        }
    }

    private var hoursField: some View {
        HStack {
            Text("Hours")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            TextField("0", text: $hoursText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Actions

    private func addDraftTag() {
        let cleaned = tagDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        guard !cleaned.isEmpty, !tags.contains(cleaned) else {
            tagDraft = ""
            return
        }
        withAnimation(WARMotion.spring) {
            tags.append(cleaned)
        }
        tagDraft = ""
    }

    private func save() {
        let hours = Double(hoursText.trimmingCharacters(in: .whitespacesAndNewlines))

        if let entryToEdit {
            store.update(
                entryToEdit,
                date: date,
                text: trimmedText,
                category: category,
                performanceFactor: performanceFactor,
                tags: tags,
                impact: impact,
                beneficiary: beneficiary,
                hours: hours
            )
        } else {
            store.addEntry(
                baseID: baseID,
                date: date,
                text: trimmedText,
                category: category,
                performanceFactor: performanceFactor,
                tags: tags,
                impact: impact,
                beneficiary: beneficiary,
                hours: hours,
                memberType: WARSettingsStore.memberType
            )
        }
        dismiss()
    }
}

// MARK: - Category chips

private struct WARCategoryChipRow: View {
    @Binding var selection: WARCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WARCategory.allCases) { category in
                    Button {
                        withAnimation(WARMotion.spring) {
                            selection = category
                        }
                    } label: {
                        Label(category.title, systemImage: category.systemImage)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selection == category
                                    ? AnyShapeStyle(category.tint.opacity(0.18))
                                    : AnyShapeStyle(Color(.tertiarySystemFill)),
                                in: Capsule()
                            )
                            .foregroundStyle(selection == category ? category.tint : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: selection == category)
                }
            }
        }
    }
}

private struct WARTagChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(AppTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.accent.opacity(0.12), in: Capsule())
    }
}

#if DEBUG
#Preview {
    WARQuickAddSheet(baseID: "keesler", defaultDate: Date(), locksDate: true)
        .environment(WARTrackerStore(modelContext: ModelContainerFactory.preview().mainContext))
}
#endif
