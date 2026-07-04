import Foundation

struct AFISearchPreparationFailure: Equatable {
    let title: String
    let message: String
}

enum AFISearchCopy {
    static let indexingTitle = "Preparing Offline Search"
    static let indexingFooter =
        "This one-time setup builds a searchable index on your device. You can keep using other parts of the app while it finishes — search stays available offline afterward."

    static let bundledParseFailure = AFISearchPreparationFailure(
        title: "Search Library Not Included",
        message: "This build doesn't include a full AFI search library yet. Use the publication links below to open official PDFs on e-Publishing."
    )

    static let indexBuildFailure = AFISearchPreparationFailure(
        title: "Search Isn't Ready Yet",
        message: "MyAFBase couldn't finish building the offline search index from the bundled AFIs. Force-quit and reopen the app, or use the publication links below."
    )

    static let corpusUnavailable = AFISearchPreparationFailure(
        title: "Search Content Unavailable",
        message: "The AFI search library couldn't be loaded from this build. Use the publication links below to open official PDFs."
    )

    static let searchFailed = AFISearchPreparationFailure(
        title: "Search Interrupted",
        message: "Something went wrong while searching. Try your query again in a moment."
    )

    static let noResultsTitle = "No Matches Found"
    static let noResultsMessage =
        "Nothing in the Essential AFIs matched that query. Try shorter keywords, a publication number like \"DAFI 36-3003\", or topics like convalescent leave, PT test, or beard waiver."

    static let readyHintTitle = "Search Essential AFIs"
    static let readyHintMessage =
        "Find passages in dress & appearance, leave, fitness, blue book, and other go-to publications — with citations you can verify on e-Publishing."

    static let exampleQueries = [
        "convalescent leave",
        "PT test",
        "beard waiver",
        "air force",
        "ordinary leave"
    ]
}
