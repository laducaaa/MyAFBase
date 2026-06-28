import SwiftUI

struct ExploreCategoryItemData: Identifiable {
    let id: String
    let displayName: String
    let systemImage: String
}

struct ExploreCategoryBar: View {
    let categories: [ExploreCategoryItemData]
    @Binding var selectedID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    Button {
                        selectedID = category.id
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(ExploreMetrics.categoryIconFont)
                                .frame(height: 24)

                            Text(category.displayName)
                                .font(ExploreMetrics.categoryLabelFont)
                                .fontWeight(selectedID == category.id ? .semibold : .medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Capsule()
                                .fill(selectedID == category.id ? AppTheme.accent : Color.clear)
                                .frame(width: 28, height: ExploreMetrics.categoryUnderlineHeight)
                        }
                        .frame(width: ExploreMetrics.categoryItemWidth)
                        .foregroundStyle(selectedID == category.id ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(category.displayName)
                    .accessibilityAddTraits(selectedID == category.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

extension ExploreCategory {
    var itemData: ExploreCategoryItemData {
        ExploreCategoryItemData(id: id, displayName: displayName, systemImage: systemImage)
    }
}

extension EventExploreCategory {
    var itemData: ExploreCategoryItemData {
        ExploreCategoryItemData(id: id, displayName: displayName, systemImage: systemImage)
    }
}
