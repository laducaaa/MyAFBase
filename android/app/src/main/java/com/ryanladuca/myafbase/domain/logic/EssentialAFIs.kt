package com.ryanladuca.myafbase.domain.logic

data class EssentialAFI(
    val id: String,
    val title: String,
    val publication: String,
    val fallbackUrl: String
)

object EssentialAFIs {
    val stationed: List<EssentialAFI> = listOf(
        EssentialAFI(
            id = "dress-appearance",
            title = "Dress & Appearance",
            publication = "DAFI 36-2903",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2903/dafi36-2903.pdf"
        ),
        EssentialAFI(
            id = "afh1",
            title = "The Air Force",
            publication = "AFH 1 · Blue Book",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/afh1/afh1.pdf"
        ),
        EssentialAFI(
            id = "enlisted-force",
            title = "Enlisted Force",
            publication = "DAFI 36-2618",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2618/dafi36-2618.pdf"
        ),
        EssentialAFI(
            id = "officer-pd",
            title = "Officer Development",
            publication = "DAFI 36-2643",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2643/dafi36-2643.pdf"
        ),
        EssentialAFI(
            id = "fitness",
            title = "Fitness Program",
            publication = "DAFI 36-2905",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2905/dafi36-2905.pdf"
        ),
        EssentialAFI(
            id = "decorations",
            title = "Decorations",
            publication = "DAFMAN 36-2806",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafman36-2806/dafman36-2806.pdf"
        ),
        EssentialAFI(
            id = "leave",
            title = "Military Leave",
            publication = "DAFI 36-3003",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-3003/dafi36-3003.pdf"
        ),
        EssentialAFI(
            id = "justice",
            title = "Military Justice",
            publication = "DAFI 51-201",
            fallbackUrl = "https://static.e-publishing.af.mil/production/1/af_ja/publication/dafi51-201/dafi51-201.pdf"
        )
    )

    fun bundledAssetPath(publicationId: String): String? {
        val known = stationed.any { it.id == publicationId }
        return if (known) "afi/pdfs/$publicationId.pdf" else null
    }

    fun findByPublicationId(publicationId: String): EssentialAFI? =
        stationed.firstOrNull { it.id == publicationId }
}
