//
//  WeatherUtils.swift
//  TermiWatch
//
//  Created by Qianlishun on 2023/10/10.
//  Copyright © 2023 Librecz Gábor. All rights reserved.
//
import Foundation
import WeatherKit
import CoreLocation
import SwiftUI
import OSLog


private let weatherLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "Weather")

struct WeatherInfo {
    let current: QWeather
    let weathers: [QWeather] // Index 0 is current weather
    let alerts: [String]

    init(current: QWeather, weathers: [QWeather], alerts: [String]) {
        self.current = current
        self.weathers = weathers
        self.alerts = alerts
    }

    init(){
        self.init(current: QWeather(), weathers: [QWeather()], alerts: [String()] )
    }

    init(current: HFWeatherNow, weathers: [HFWeather24h]){
        var weathers2 = weathers.map({ hf in
            QWeather(hfWeather: hf)
        })
        let currentQ = QWeather(hfWeather: current)
        weathers2.insert(currentQ, at: 0)
        self.init(current: currentQ, weathers: weathers2, alerts: [String()])
    }
}
struct QTemperature{
    let value: String
    let unit: String
    init(value: String, unit: String) {
        self.value = value
        self.unit = unit
    }
    init(_ str: String){
        if str.count == 0{
            self.init()
        }else{
            let unitIndex = str.index(str.endIndex, offsetBy: -1)
            let unit = String(str[unitIndex])
            var temp = str.replacingOccurrences(of: unit, with: "")
            if(temp == "-0"){
                temp = "0"
            }
            self.init(value: temp, unit: unit)
        }
    }
    init(){
        self.init(value: "0", unit: "℃")
    }
}
struct QWeather{
    let date: Date
    let condition: String
    let symbol: String
    let temperature: QTemperature
    let humidity: String

    init(date: Date, condition: String, symbol: String, temperature: String, humidity: String) {
        self.date = date
        self.condition = condition
        self.symbol = symbol
        self.temperature = QTemperature(temperature)
        self.humidity = humidity
    }
    init() {
        self.init(date: Date() , condition: "", symbol: "sparkles", temperature: "",humidity: "")
    }

    init(currentWeather: CurrentWeather, tempMF: MeasurementFormatter){
        let condition = currentWeather.condition
        let symbol = currentWeather.symbolName
        let temperature = currentWeather.temperature
        let temp = tempMF.string(from: temperature)
        let humidity = String("\(Int(currentWeather.humidity*100))%")
        self.init(date: currentWeather.date, condition: condition.description, symbol: symbol, temperature: temp, humidity: humidity)
    }
    init(hourWeather: HourWeather, tempMF: MeasurementFormatter){
        let condition = hourWeather.condition
        let symbol = hourWeather.symbolName
        let temperature = hourWeather.temperature
        let temp = tempMF.string(from: temperature)
        let humidity = String("\(Int(hourWeather.humidity*100))%")
        self.init(date: hourWeather.date, condition: condition.accessibilityDescription, symbol: symbol, temperature: temp, humidity: humidity)
    }
    init(hfWeather: HFWeatherNow){
        self.init(date: hfWeather.obsTime, condition: hfWeather.text, symbol: hfWeather.icon, temperature: hfWeather.temp+"℃", humidity: hfWeather.humidity+"%")
    }
    init(hfWeather: HFWeather24h){
        self.init(date: hfWeather.fxTime, condition: hfWeather.text, symbol: hfWeather.icon, temperature: hfWeather.temp+"℃", humidity: hfWeather.humidity+"%")
    }
}

//, completion: @escaping(String) -> ()
func getWeather(location: CLLocation, afterHours: Int) async throws -> WeatherInfo {
    let weatherService = WeatherService()

    var result: WeatherInfo = WeatherInfo()
    do {

        let formatter = MeasurementFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: afterHours ,to: Date.now)

        let weather = try await weatherService.weather(for: location,including: .current, .hourly(startDate: Date.now, endDate: endDate!),.alerts)

        let current = QWeather(currentWeather: weather.0, tempMF: formatter )

        var afters = [QWeather]()
        for hourWeather in weather.1.forecast.prefix(afterHours){
            let after = QWeather(hourWeather: hourWeather, tempMF: formatter )
            afters.append(after)
        }

        var alerts = [String]()
        for alert in (weather.2 ?? []).prefix(afterHours) {
            alerts.append(alert.summary)
        }
        while alerts.count < afterHours {
            alerts.append("")
        }

        result = WeatherInfo(current: current, weathers: [current] + afters, alerts: alerts)

    }catch {

        weatherLogger.error("WatchWeatherCall error: \(error.localizedDescription, privacy: .public)")
    }

    return result
}

func HFWeatherNowAPI(
    location: CLLocation,
    apiKey: String = HFWeatherKey
) -> URL {
  return URL(
    string: "https://devapi.qweather.com/v7/weather/now?"
        + "location=\(location.coordinate.longitude),\(location.coordinate.latitude)"
        + "&key=\(apiKey)"
  )!
}
func HFWeather24hAPI(
    location: CLLocation,
    apiKey: String = HFWeatherKey
) -> URL {
  return URL(
    string: "https://devapi.qweather.com/v7/weather/24h?"
        + "location=\(location.coordinate.longitude),\(location.coordinate.latitude)"
        + "&key=\(apiKey)"
  )!
}

struct HFWeatherNow : Codable {
    let obsTime: Date
    let text: String
    let icon: String
    let temp: String
    let humidity: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        obsTime = try container.decode(Date.self, forKey: .obsTime)
        text = try container.decode(String.self, forKey: .text)
        let iconStr = try container.decode(String.self, forKey: .icon)
        icon = "svg".appending(iconStr)
        temp = try container.decode(String.self, forKey: .temp)
        humidity = try container.decode(String.self, forKey: .humidity)
    }
    init(obsTime: Date, text: String, icon: String, temp: String, humidity: String) {
        self.obsTime = obsTime
        self.text = text
        self.icon = "svg".appending(icon)
        self.temp = temp
        self.humidity = humidity
    }
    init(){
        self.init(obsTime: Date(), text: "", icon: "999", temp: "", humidity: "")
    }
}

struct HFWeather24h : Codable {
    let fxTime: Date
    let text: String
    let icon: String
    let temp: String
    let humidity: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fxTime = try container.decode(Date.self, forKey: .fxTime)
        text = try container.decode(String.self, forKey: .text)
        let iconStr = try container.decode(String.self, forKey: .icon)
        icon = "svg".appending(iconStr)
        temp = try container.decode(String.self, forKey: .temp)
        humidity = try container.decode(String.self, forKey: .humidity)
    }
    init(fxTime: Date, text: String, icon: String, temp: String, humidity: String) {
        self.fxTime = fxTime
        self.text = text
        self.icon = "svg".appending(icon)
        self.temp = temp
        self.humidity = humidity
    }
    init(){
        self.init(fxTime:Date(),  text: "", icon: "999", temp: "", humidity: "")
    }
}


struct HFWeatherNowResponse: Codable {
    let code: String
    let now: HFWeatherNow

}
struct HFWeather24hResponse: Codable {
    let code: String
    let hourly: [HFWeather24h]

}
func getHFWeather(location: CLLocation, handler: (@escaping (WeatherInfo) -> Void) ) {

    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
    sessionConfig.urlCache = nil

    var request = URLRequest(url: HFWeatherNowAPI(location: location))
    request.httpMethod = "GET"
    request.setValue("UTF-8", forHTTPHeaderField:"Charset")
    request.setValue("application/json", forHTTPHeaderField:"Content-Type")

    var request2 = URLRequest(url: HFWeather24hAPI(location: location))
    request2.httpMethod = "GET"
    request2.setValue("UTF-8", forHTTPHeaderField:"Charset")
    request2.setValue("application/json", forHTTPHeaderField:"Content-Type")

    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZ"
    decoder.dateDecodingStrategy = .formatted(formatter)

    URLSession(configuration: sessionConfig).dataTask(with: request) { data, response, error in
        do {
            if(data == nil){
                weatherLogger.error("QWeather current request failed: \(error?.localizedDescription ?? "Unknown error", privacy: .public)")
                handler(WeatherInfo())
                return
            }
            let result = try decoder.decode(HFWeatherNowResponse.self, from: data!)
            if(result.code == "200"){

                URLSession(configuration: sessionConfig).dataTask(with: request2) { data, response, error in
                    do {
                        guard let data = data else {
                            weatherLogger.error("QWeather hourly request failed: \(error?.localizedDescription ?? "Unknown error", privacy: .public)")
                            handler(WeatherInfo())
                            return
                        }

                        let result2 = try decoder.decode(HFWeather24hResponse.self, from: data)
                        if(result2.code == "200"){
                            let hf = WeatherInfo(current: result.now, weathers: result2.hourly)
                            handler(hf)
                            weatherLogger.debug("QWeather response parsed successfully.")
                        }else{
                            weatherLogger.error("QWeather hourly API error: \(result2.code, privacy: .public)")

                            handler(WeatherInfo())
                        }

                    } catch {
                        weatherLogger.error("Unable to connect to server: \(error.localizedDescription, privacy: .public)")
                        handler(WeatherInfo())
                    }
                }.resume()


            }else{
                weatherLogger.error("QWeather current API error: \(result.code, privacy: .public)")

                handler(WeatherInfo())
            }

        } catch {
            weatherLogger.error("Unable to connect to server: \(error.localizedDescription, privacy: .public)")
            handler(WeatherInfo())
        }
    }.resume()

}

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    var lastLocation: String {
        get {
            qUserdefaults?.string(forKey: "LastLocation") ?? defaultCity
        }
        set {
            qUserdefaults?.set(newValue, forKey: "LastLocation")
            weatherLogger.debug("lastLocation didSet")
        }
    }

    var lastLocationTime: String {
        get {
            qUserdefaults?.string(forKey: "LastLocationTime") ?? ""
        }
        set {
            qUserdefaults?.set(newValue, forKey: "LastLocationTime")
            weatherLogger.debug("LastLocationTime didSet")
        }
    }


    var locationManager: CLLocationManager?
    private var handlers: [(CLLocation) -> Void] = []
    private var isWaitingForAuthorization = false

//    var lastLati = UserDefaults.standard.object(forKey: "LastLocation.lati") ?? 0
//    var lastLong = UserDefaults.standard.object(forKey: "LastLocation.long") ?? 0
//    var updateTime:Date = UserDefaults.standard.object(forKey: "LastLocationTime") as? Date ?? Date.init(timeIntervalSinceNow: -30)

    override init() {
        super.init()
        if Thread.isMainThread {
            configureLocationManager()
        } else {
            DispatchQueue.main.sync {
                configureLocationManager()
            }
        }
    }

    func fetchLocation(handler: @escaping (CLLocation) -> Void) {
        DispatchQueue.main.async {
            self.fetchLocationOnMain(handler: handler)
        }
    }

    private func configureLocationManager() {
        guard locationManager == nil else { return }

        let locationManager = CLLocationManager()
        locationManager.delegate = self
        self.locationManager = locationManager

        let status = locationManager.authorizationStatus
        weatherLogger.debug("Location status: \(String(describing: status), privacy: .public)")
        if status == .notDetermined {
            isWaitingForAuthorization = true
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func fetchLocationOnMain(handler: @escaping (CLLocation) -> Void) {
        weatherLogger.debug("Cached location: \(self.lastLocation, privacy: .public), time: \(self.lastLocationTime, privacy: .public)")

        let now:Double = Date().timeIntervalSince1970
        let last:Double = Double(lastLocationTime) ?? 0

        if( (now - last) < 3600*12){
            weatherLogger.debug("Using cached location")
            let location = CLLocation(string: lastLocation)
            handler(location)
            return
        }

        guard let locationManager else {
            configureLocationManager()
            fetchLocationOnMain(handler: handler)
            return
        }

        handlers.append(handler)

        switch locationManager.authorizationStatus {
        case .notDetermined:
            isWaitingForAuthorization = true
            locationManager.requestWhenInUseAuthorization()
            weatherLogger.debug("Waiting for location authorization")
            return
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .denied, .restricted:
            weatherLogger.error("Location authorization denied or restricted; using cached location.")
            completeLocationRequests(with: CLLocation(string: lastLocation))
            return
        @unknown default:
            weatherLogger.error("Unknown location authorization status; using cached location.")
            completeLocationRequests(with: CLLocation(string: lastLocation))
            return
        }

        locationManager.requestLocation()
        weatherLogger.debug("Requested location")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        weatherLogger.debug("Location authorization changed: \(String(describing: status), privacy: .public)")

        guard isWaitingForAuthorization else { return }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            isWaitingForAuthorization = false
            guard !handlers.isEmpty else { return }
            manager.requestLocation()
            weatherLogger.debug("Requested location after authorization")
        case .denied, .restricted:
            isWaitingForAuthorization = false
            completeLocationRequests(with: CLLocation(string: lastLocation))
        case .notDetermined:
            break
        @unknown default:
            isWaitingForAuthorization = false
            completeLocationRequests(with: CLLocation(string: lastLocation))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            completeLocationRequests(with: CLLocation(string: lastLocation))
            return
        }
//        lastLati = location.coordinate.latitude
//        lastLong = location.coordinate.longitude
//
//        updateTime = Date()
        weatherLogger.debug("Did update locations: \(String(describing: locations), privacy: .public)")
//
//        UserDefaults.standard.set(lastLati, forKey: "LastLocation.lati")
//        UserDefaults.standard.set(lastLong, forKey: "LastLocation.long")
//        UserDefaults.standard.set(updateTime, forKey: "LastLocationTime")
        manager.stopUpdatingLocation()


        lastLocation = location.string()
        lastLocationTime = Date().since1970TimeIntervalString();

        completeLocationRequests(with: location)
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        weatherLogger.error("Location update failed: \(error.localizedDescription, privacy: .public)")
        let location = CLLocation(string: lastLocation)
        completeLocationRequests(with: location)
    }

    private func completeLocationRequests(with location: CLLocation) {
        let pendingHandlers = handlers
        handlers.removeAll()

        pendingHandlers.forEach { handler in
            handler(location)
        }
    }
}

extension CLLocation{

    func string() -> String{
        return "\(self.coordinate.latitude),\(self.coordinate.longitude)"
    }

    convenience init(string: String){
        let array = string.components(separatedBy: CharacterSet(charactersIn: ","))
        let latitude = Double(array[0]) ?? 0
        let longitude = Double(array[1]) ?? 0

        self.init(latitude: latitude, longitude: longitude)
    }

}
extension Date{

    func since1970TimeIntervalString() -> String{
        return "\(timeIntervalSince1970)"
    }

    init(since1970: String){
        let time = TimeInterval(Double(since1970) ?? 0)
        self.init(timeIntervalSince1970: time)
    }

}
