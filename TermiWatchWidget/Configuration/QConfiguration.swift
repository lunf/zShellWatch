//
//  Config.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/27.
//

import Foundation

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

let qFaceLineOrderKey = "qFaceLineOrderKey"
let qFaceThemeKey = "qFaceThemeKey"
let qFaceAnimationKey = "qFaceAnimationKey"
let qWatchSessionSyncCommandKey = "syncCommand"
let qWatchSessionSyncSettingsCommand = "syncSettings"

/// Health info refresh interval, unit: minutes. On demand adjustment, due to the daily refresh limit, setting too many refresh frequencies may result in not refreshing again on the same day after the refresh times are exhausted.
let healthRefreshInterval = 15
