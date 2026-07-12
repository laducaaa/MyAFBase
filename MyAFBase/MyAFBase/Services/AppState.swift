import Foundation
import Observation

enum ExploreDestination: String, Equatable {
    case gates
    case resources
    case events
}

@Observable
final class AppState {
    var selectedBaseID: String?
    var currentBase: Base?
    var weather: Weather?
    var weatherBaseID: String?
    var isWeatherLoading = false
    var shouldShowBasePicker = false
    var shouldShowOnboarding = false
    var pendingExploreDestination: ExploreDestination?
    var pendingExploreCategoryID: String?
    var pendingExploreOpenNowOnly = false
    var pendingHomeNavigation = false
    var showWARQuickLog = false
    var pendingWARQuickLogText = ""
    var currentBaseRegion: BaseRegion?
    var showCONUSWeatherInHero: Bool

    private let dataService: BaseDataProviding
    private let weatherService: WeatherService
    private let selectedBaseKey = AppIntentBaseSelection.selectedBaseKey
    private let showCONUSWeatherKey = "showCONUSWeatherInHero"
    private let onboardingCompletedKey = "hasCompletedOnboarding"

    var isBaseLoading: Bool {
        selectedBaseID != nil && currentBase == nil
    }

    var shouldShowWeatherInHero: Bool {
        currentBaseRegion == .conus && showCONUSWeatherInHero
    }

    var weatherMatchesCurrentBase: Bool {
        guard let baseID = currentBase?.id else { return false }
        return weatherBaseID == baseID
    }

    var displayWeather: Weather? {
        weatherMatchesCurrentBase ? weather : nil
    }

    init(
        dataService: BaseDataProviding = RemoteAwareBaseDataService(),
        weatherService: WeatherService = .shared
    ) {
        self.dataService = dataService
        self.weatherService = weatherService
        if UserDefaults.standard.object(forKey: showCONUSWeatherKey) != nil {
            self.showCONUSWeatherInHero = UserDefaults.standard.bool(forKey: showCONUSWeatherKey)
        } else {
            self.showCONUSWeatherInHero = true
        }
        loadLastBase()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        shouldShowOnboarding = false

        if selectedBaseID == nil {
            shouldShowBasePicker = true
        }
    }

    func beginSelectingBase(id: String, region: BaseRegion? = nil) {
        if selectedBaseID != id {
            weather = nil
            weatherBaseID = nil
        }

        selectedBaseID = id
        currentBase = nil
        currentBaseRegion = region
        UserDefaults.standard.set(id, forKey: selectedBaseKey)
        shouldShowBasePicker = false
    }

    func loadSelectedBase(id: String, region: BaseRegion? = nil) async {
        let base = await dataService.loadBase(id: id)

        guard selectedBaseID == id else { return }

        currentBase = base

        if region == nil {
            currentBaseRegion = await dataService.region(for: id)
        }

        shouldShowBasePicker = base == nil

        // Open Now is published with saved items from `ContentView`'s
        // `.onChange(of: appState.currentBase)`, which has access to the
        // bookmark store. Publishing here too (without saved items) would
        // race with — and sometimes overwrite — that authoritative update.
        if let base {
            HomeWidgetSync.publishEmergency(base: base)
        }

        Task { await refreshWeather() }
    }

    func selectBase(id: String, region: BaseRegion? = nil) async {
        beginSelectingBase(id: id, region: region)
        await loadSelectedBase(id: id, region: region)
    }

    func setShowCONUSWeatherInHero(_ enabled: Bool) {
        showCONUSWeatherInHero = enabled
        UserDefaults.standard.set(enabled, forKey: showCONUSWeatherKey)

        if enabled {
            Task { await refreshWeather() }
        } else {
            weather = nil
            weatherBaseID = nil
            isWeatherLoading = false
        }
    }

    func refreshWeather(force: Bool = false) async {
        guard let base = currentBase else {
            weather = nil
            weatherBaseID = nil
            return
        }

        let baseID = base.id
        let showInHero = shouldShowWeatherInHero

        if showInHero {
            if weatherBaseID != baseID {
                weather = nil
            }
            isWeatherLoading = true
        }

        let fetched = await weatherService.fetchWeather(
            lat: base.latitude,
            lon: base.longitude,
            forceRefresh: force
        )

        guard currentBase?.id == baseID else {
            isWeatherLoading = false
            return
        }

        applyWeatherFetch(fetched, base: base, baseID: baseID, showInHero: showInHero)
    }

    private func applyWeatherFetch(_ fetched: Weather, base: Base, baseID: String, showInHero: Bool) {
        let widgetWeather = fetched.isPlaceholder ? nil : fetched
        HomeWidgetSync.publishWeather(base: base, weather: widgetWeather)

        if showInHero {
            weather = widgetWeather
            weatherBaseID = widgetWeather == nil ? nil : baseID
        } else {
            weather = nil
            weatherBaseID = nil
        }

        isWeatherLoading = false
    }

    func refreshAll() async {
        guard let id = selectedBaseID else { return }
        await dataService.syncRemoteUpdates(force: true, baseID: id)
        currentBase = await dataService.loadBase(id: id)
        if let base = currentBase {
            HomeWidgetSync.publishEmergency(base: base)
        }
        await refreshWeather(force: true)
    }

    func syncRemoteBaseData() async {
        await dataService.syncRemoteUpdates(force: false, baseID: selectedBaseID)
        if let id = selectedBaseID {
            await loadSelectedBase(id: id, region: currentBaseRegion)
        }
    }

    func loadBaseIndex() async -> [BaseIndexEntry] {
        await dataService.loadPickerBaseIndex()
    }

    func loadFullBaseIndex() async -> [BaseIndexEntry] {
        await dataService.loadBaseIndex()
    }

    func openExplore(_ destination: ExploreDestination, categoryID: String? = nil, openNowOnly: Bool = false) {
        pendingExploreDestination = destination
        pendingExploreCategoryID = categoryID
        pendingExploreOpenNowOnly = openNowOnly
    }

    func consumeExploreNavigation() -> (destination: ExploreDestination, categoryID: String?, openNowOnly: Bool)? {
        guard let destination = pendingExploreDestination else { return nil }
        let categoryID = pendingExploreCategoryID
        let openNowOnly = pendingExploreOpenNowOnly
        pendingExploreDestination = nil
        pendingExploreCategoryID = nil
        pendingExploreOpenNowOnly = false
        return (destination, categoryID, openNowOnly)
    }

    func consumeExploreDestination() -> ExploreDestination? {
        consumeExploreNavigation()?.destination
    }

    func requestHomeNavigation() {
        pendingHomeNavigation = true
    }

    private func loadLastBase() {
        guard UserDefaults.standard.bool(forKey: onboardingCompletedKey) else {
            shouldShowOnboarding = true
            return
        }

        guard let savedID = UserDefaults.standard.string(forKey: selectedBaseKey) else {
            shouldShowBasePicker = true
            return
        }

        Task {
            await selectBase(id: savedID)
        }
    }
}
