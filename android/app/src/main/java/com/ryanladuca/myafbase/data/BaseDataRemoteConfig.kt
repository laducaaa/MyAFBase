package com.ryanladuca.myafbase.data

object BaseDataRemoteConfig {
    const val REPOSITORY = "laducaaa/MyAFBase"
    const val PINNED_REF = "main"
    const val BASES_PATH = "MyAFBase/MyAFBase/Resources/Bases"
    const val INDEX_REFRESH_INTERVAL_MS = 60 * 60 * 1000L
    const val BASE_REFRESH_INTERVAL_MS = 30 * 60 * 1000L

    val indexUrl: String
        get() = remoteUrl("bases_index.json")

    fun baseUrl(id: String): String = remoteUrl("$id.json")

    private fun remoteUrl(filename: String): String =
        "https://raw.githubusercontent.com/$REPOSITORY/$PINNED_REF/$BASES_PATH/$filename"
}
