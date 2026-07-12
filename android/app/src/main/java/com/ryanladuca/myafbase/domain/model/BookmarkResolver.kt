package com.ryanladuca.myafbase.domain.model

import com.ryanladuca.myafbase.data.db.BookmarkEntity

sealed class ResolvedBookmark {
    abstract val bookmark: BookmarkEntity
    abstract val title: String
    abstract val subtitle: String?

    data class GateItem(
        override val bookmark: BookmarkEntity,
        val gate: Gate
    ) : ResolvedBookmark() {
        override val title: String get() = gate.name
        override val subtitle: String? get() = gate.hours
    }

    data class ResourceItem(
        override val bookmark: BookmarkEntity,
        val resource: Resource
    ) : ResolvedBookmark() {
        override val title: String get() = resource.name
        override val subtitle: String?
            get() = listOfNotNull(resource.category, resource.displayHours).joinToString(" · ")
    }

    data class EventItem(
        override val bookmark: BookmarkEntity,
        val event: Event
    ) : ResolvedBookmark() {
        override val title: String get() = event.title
        override val subtitle: String? get() = event.displayAddress ?: event.date
    }

    data class Orphan(
        override val bookmark: BookmarkEntity
    ) : ResolvedBookmark() {
        override val title: String get() = bookmark.title
        override val subtitle: String? get() = bookmark.subtitle ?: "Unavailable on this base"
    }
}

enum class HomeSavedCategory(val label: String) {
    ALL("All"),
    GATES("Gates"),
    RESOURCES("Resources"),
    EVENTS("Events")
}

object BookmarkResolver {
    fun resolve(base: Base, bookmarks: List<BookmarkEntity>): List<ResolvedBookmark> {
        return bookmarks.map { bookmark ->
            when (BookmarkTargetType.fromRaw(bookmark.targetType)) {
                BookmarkTargetType.GATE -> {
                    val gate = base.gates.firstOrNull { it.id == bookmark.targetId }
                    if (gate != null) ResolvedBookmark.GateItem(bookmark, gate)
                    else ResolvedBookmark.Orphan(bookmark)
                }
                BookmarkTargetType.RESOURCE -> {
                    val resource = base.resources.firstOrNull { it.id == bookmark.targetId }
                    if (resource != null) ResolvedBookmark.ResourceItem(bookmark, resource)
                    else ResolvedBookmark.Orphan(bookmark)
                }
                BookmarkTargetType.EVENT -> {
                    val event = base.events.firstOrNull { it.id == bookmark.targetId }
                    if (event != null) ResolvedBookmark.EventItem(bookmark, event)
                    else ResolvedBookmark.Orphan(bookmark)
                }
            }
        }
    }

    fun filter(
        items: List<ResolvedBookmark>,
        category: HomeSavedCategory
    ): List<ResolvedBookmark> = when (category) {
        HomeSavedCategory.ALL -> items
        HomeSavedCategory.GATES -> items.filter { it is ResolvedBookmark.GateItem }
        HomeSavedCategory.RESOURCES -> items.filter { it is ResolvedBookmark.ResourceItem }
        HomeSavedCategory.EVENTS -> items.filter { it is ResolvedBookmark.EventItem }
    }
}
