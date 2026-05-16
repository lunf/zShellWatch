//
//  Config.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/27.
//

import Foundation
import SwiftUI

/*
 Personal development teams cannot sign the WeatherKit entitlement. Keep
 qUseWeatherKit false unless you have a paid Apple Developer account and have
 enabled WeatherKit for the app identifier.

 If the QWeather API key is configured, QWeather is used before WeatherKit.
 https://dev.qweather.com
 Chinese docs https://dev.qweather.com/docs/configuration/project-and-key/
 English https://dev.qweather.com/en/docs/configuration/project-and-key/
 */
let qUseWeatherKit = false
let HFWeatherKey = ""
let qUseHealthKit = true

var qWeatherSourceName: String {
    if !HFWeatherKey.isEmpty {
        return "QWeather"
    }
    return qUseWeatherKit ? "WeatherKit" : "Disabled"
}

let qGroupBundleID = "group.com.github.lunf.zShellWatch"

let qUserdefaults: UserDefaults? = {
    guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: qGroupBundleID) != nil else {
        return .standard
    }

    return UserDefaults(suiteName: qGroupBundleID) ?? .standard
}()

func terminalName() -> String {
    if let name = qUserdefaults?.string(forKey: qUserNameKey){
        return name
    }
    return "void"
}

func machineName() -> String {
    if let name = qUserdefaults?.string(forKey: qMachineNameKey), !name.isEmpty {
        return name
    }
    return "local"
}

let defaultCity = "39.9042, 116.4074" //  (latitude, longitude)

let qUserNameKey = "qUserNameKey"
let qMachineNameKey = "qMachineNameKey"
let qLeftTopImageKey =  "qLeftTopImageKey"
let qCustomLeftTopImageKey =  "qCustomLeftTopImageKey"

let qWeatherImageKey = "qWeatherImageKey"
let qHealthImageKey = "qHealthImageKey"
let qFaceImageKey = "qFaceImageKey"
let qCustomImageKey = "qCustomImageKey"
let qFaceLineOrderKey = "qFaceLineOrderKey"

enum TermiFaceLine: String, CaseIterable, Identifiable {
    case promptNow
    case date
    case time
    case currentWeather
    case temperature
    case humidity
    case nextWeather
    case battery
    case rings
    case steps
    case calories
    case heartRate
    case prompt

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .promptNow: return "Command Prompt"
        case .date: return "Date"
        case .time: return "Time"
        case .currentWeather: return "Current Weather"
        case .temperature: return "Temperature"
        case .humidity: return "Humidity"
        case .nextWeather: return "Next Weather"
        case .battery: return "Battery"
        case .rings: return "Rings"
        case .steps: return "Steps"
        case .calories: return "Calories"
        case .heartRate: return "Heart Rate"
        case .prompt: return "Prompt"
        }
    }
}

let qDefaultFaceLines: [TermiFaceLine] = [
    .promptNow,
    .currentWeather,
    .temperature,
    .humidity,
    .nextWeather,
    .rings,
    .steps,
    .calories,
    .heartRate,
    .prompt
]

func selectedFaceLines(userDefaults: UserDefaults? = qUserdefaults) -> [TermiFaceLine] {
    guard let lineIDs = userDefaults?.stringArray(forKey: qFaceLineOrderKey) else {
        return qDefaultFaceLines
    }

    let lines = lineIDs.compactMap(TermiFaceLine.init(rawValue:))
    return lines.isEmpty ? qDefaultFaceLines : lines
}

func saveSelectedFaceLines(_ lines: [TermiFaceLine], userDefaults: UserDefaults? = qUserdefaults) {
    userDefaults?.set(lines.map(\.rawValue), forKey: qFaceLineOrderKey)
    userDefaults?.synchronize()
}

/// Health info refresh interval, unit: minutes. On demand adjustment, due to the daily refresh limit, setting too many refresh frequencies may result in not refreshing again on the same day after the refresh times are exhausted.
let healthRefreshInterval = 15

let colorDate = Color.orange
let colorAlert1 = Color.yellow
let colorAlert2 = Color.red
let colorTemp = Color(r: 253, g: 143, b: 63)
let colorHumi = Color.blue
let colorCond = Color(r: 255, g: 215, b: 0)
let colorWind = Color.white

let colorKeep1 = Color.cyan
let colorKeep2 = Color.brown
let colorStep = Color.indigo
let colorKcal = Color(r:238,g:98,b:48)
let colorHR = Color(r:235,g:74,b:98)
let qRowHeight = 14.0
let qFaceRowSpacing = 3.0
let qFacePaddingTop = 20.0
let qFacePaddingHorizontal = 12.0
let qFacePaddingBottom = 12.0
let qFontSize = 13.0
