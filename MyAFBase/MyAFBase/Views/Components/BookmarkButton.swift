import SwiftUI

struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void

    @State private var bookmarkTick = 0
    @State private var removalScale: CGFloat = 1

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(ExploreMetrics.bookmarkIconFont)
                .foregroundStyle(isBookmarked ? AppTheme.accent : Color.secondary)
                .frame(width: 28, height: 28)
                .scaleEffect(removalScale)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, options: .nonRepeating, value: bookmarkTick)
        }
        .buttonStyle(BookmarkPressButtonStyle(isBookmarked: isBookmarked))
        .animation(bookmarkStateAnimation, value: isBookmarked)
        .onChange(of: isBookmarked) { _, bookmarked in
            if bookmarked {
                bookmarkTick += 1
                removalScale = 1
            } else {
                animateRemoval()
            }
        }
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
    }

    private var bookmarkStateAnimation: Animation {
        isBookmarked
            ? .spring(response: 0.32, dampingFraction: 0.68)
            : .easeOut(duration: 0.2)
    }

    private func animateRemoval() {
        withAnimation(.easeOut(duration: 0.14)) {
            removalScale = 0.9
        }

        withAnimation(.easeOut(duration: 0.22).delay(0.06)) {
            removalScale = 1
        }
    }
}

private struct BookmarkPressButtonStyle: ButtonStyle {
    let isBookmarked: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(pressScale(isPressed: configuration.isPressed))
            .animation(.spring(response: 0.24, dampingFraction: 0.55), value: configuration.isPressed)
    }

    private func pressScale(isPressed: Bool) -> CGFloat {
        guard isPressed else { return 1 }
        return isBookmarked ? 0.86 : 0.78
    }
}
