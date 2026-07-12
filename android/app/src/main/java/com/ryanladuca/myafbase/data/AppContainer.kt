package com.ryanladuca.myafbase.data

import android.content.Context
import androidx.room.Room
import com.ryanladuca.myafbase.data.db.AppDatabase
import com.ryanladuca.myafbase.data.local.BaseDataDiskCache
import com.ryanladuca.myafbase.data.local.LocalBaseDataSource
import com.ryanladuca.myafbase.data.prefs.PFRAProfileStore
import com.ryanladuca.myafbase.data.prefs.UserPreferences
import com.ryanladuca.myafbase.data.remote.RemoteBaseDataSource
import com.ryanladuca.myafbase.data.repository.BaseRepository
import com.ryanladuca.myafbase.data.repository.WeatherRepository
import com.ryanladuca.myafbase.data.repository.AfiSearchRepository
import com.ryanladuca.myafbase.data.repository.FeedbackRepository
import com.ryanladuca.myafbase.widget.WidgetDataStore
import com.ryanladuca.myafbase.widget.WidgetSync
import kotlinx.serialization.json.Json

class AppContainer(context: Context) {
    private val appContext = context.applicationContext

    val json: Json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }

    val preferences = UserPreferences(appContext)

    val database: AppDatabase = Room.databaseBuilder(
        appContext,
        AppDatabase::class.java,
        "myafbase.db"
    ).fallbackToDestructiveMigration(dropAllTables = true).build()

    private val localBaseDataSource = LocalBaseDataSource(appContext, json)
    private val remoteBaseDataSource = RemoteBaseDataSource()
    private val diskCache = BaseDataDiskCache(appContext)

    val baseRepository = BaseRepository(
        local = localBaseDataSource,
        remote = remoteBaseDataSource,
        cache = diskCache,
        json = json
    )

    val weatherRepository = WeatherRepository()
    val afiSearchRepository = AfiSearchRepository(appContext, json)
    val feedbackRepository = FeedbackRepository()
    val pfraProfileStore = PFRAProfileStore(appContext)

    val widgetDataStore = WidgetDataStore(appContext, json)
    val widgetSync = WidgetSync(appContext, widgetDataStore)

    val appState = AppState(
        preferences = preferences,
        baseRepository = baseRepository,
        weatherRepository = weatherRepository,
        widgetSync = widgetSync,
        database = database,
        appContext = appContext,
    )
}
