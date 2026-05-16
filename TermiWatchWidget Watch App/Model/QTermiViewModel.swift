//
//  QTermiViewModel.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/16.
//

import Foundation
import CoreLocation
import OSLog

private let termiViewModelLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "ViewModel")

@MainActor
private final class QTermiDataService {
    private var healthObserver: HealthObserver?
    private var widgetLocationManager: WidgetLocationManager?

    func fetchWeatherViewInfo(dateText: String? = nil) async -> WeatherViewInfo {
        guard !HFWeatherKey.isEmpty || qUseWeatherKit else {
            return WeatherViewInfo()
        }

        let location = await fetchLocation()

        if !HFWeatherKey.isEmpty {
            let weather = await fetchHFWeather(location: location)
            return makeWeatherViewInfo(from: weather, dateText: dateText)
        }

        if qUseWeatherKit {
            do {
                let weather = try await getWeather(location: location, afterHours: 2)
                return makeWeatherViewInfo(from: weather, dateText: dateText)
            } catch {
                termiViewModelLogger.error("WeatherKit fetch failed: \(error.localizedDescription, privacy: .public)")
                return WeatherViewInfo()
            }
        }

        return WeatherViewInfo()
    }

    func fetchHealthInfo() async -> HealthInfo {
        let healthObserver = getHealthObserver()

        return await withCheckedContinuation { continuation in
            healthObserver.getHealthInfo { health in
                continuation.resume(returning: health)
            }
        }
    }

    private func fetchLocation() async -> CLLocation {
        let widgetLocationManager = getWidgetLocationManager()

        return await withCheckedContinuation { continuation in
            widgetLocationManager.fetchLocation { location in
                continuation.resume(returning: location)
            }
        }
    }

    private func fetchHFWeather(location: CLLocation) async -> WeatherInfo {
        await withCheckedContinuation { continuation in
            getHFWeather(location: location) { weather in
                continuation.resume(returning: weather)
            }
        }
    }

    private func makeWeatherViewInfo(from weather: WeatherInfo, dateText: String? = nil) -> WeatherViewInfo {
        guard weather.weathers.count >= 2 else {
            return WeatherViewInfo()
        }

        let alert = weather.alerts.first ?? ""
        return WeatherViewInfo(current: weather.weathers[0], after1Hours: weather.weathers[1], alert: alert, dateText: dateText)
    }

    private func getHealthObserver() -> HealthObserver {
        if let healthObserver {
            return healthObserver
        }

        let healthObserver = HealthObserver()
        self.healthObserver = healthObserver
        return healthObserver
    }

    private func getWidgetLocationManager() -> WidgetLocationManager {
        if let widgetLocationManager {
            return widgetLocationManager
        }

        let widgetLocationManager = WidgetLocationManager()
        self.widgetLocationManager = widgetLocationManager
        return widgetLocationManager
    }
}

//  If this reports an error, set true to false to support iOS 17 and earlier.
//  If an error is reported here, it should be compatible with iOS17 or below, and true should be changed to false
#if true
@MainActor
@Observable
class QTermiViewModel {
    var health = HealthInfo()
    var weather = WeatherViewInfo()

    private let dataService = QTermiDataService()
    private var isUpdating = false

    func updateModel(){
        guard !isUpdating else {
            termiViewModelLogger.debug("updateModel skipped; update already running")
            return
        }

        isUpdating = true
        termiViewModelLogger.debug("updateModel")

        Task { @MainActor in
            defer { isUpdating = false }
            weather = await dataService.fetchWeatherViewInfo(dateText: Date().currentDate())
            health = await dataService.fetchHealthInfo()
            termiViewModelLogger.debug("Model updated")
        }
    }
}
#else

@MainActor
final class QTermiViewModel: ObservableObject {
    @Published var health = HealthInfo()
    @Published var weather = WeatherViewInfo()

    private let dataService = QTermiDataService()
    private var isUpdating = false

    func updateModel(){
        guard !isUpdating else {
            return
        }

        isUpdating = true
        Task { @MainActor in
            defer { isUpdating = false }
            weather = await dataService.fetchWeatherViewInfo()
            health = await dataService.fetchHealthInfo()
        }
    }
}

#endif
