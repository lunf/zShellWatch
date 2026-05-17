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
let qFaceThemeKey = "qFaceThemeKey"
let qFaceAnimationKey = "qFaceAnimationKey"

enum TermiFaceLine: String, CaseIterable, Identifiable, Hashable {
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

enum TermiFaceTheme: String, CaseIterable, Identifiable {
    case `default`
    case git
    case cloud
    case icon
    case colorful

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .default: return "Default Theme"
        case .git: return "Git Theme"
        case .cloud: return "Cloud Theme"
        case .icon: return "Icon Theme"
        case .colorful: return "Colorful Theme"
        }
    }

    var systemImage: String {
        switch self {
        case .default: return "terminal"
        case .git: return "arrow.triangle.branch"
        case .cloud: return "cloud.sun"
        case .icon: return "app.badge"
        case .colorful: return "paintpalette"
        }
    }

    var fontName: String {
        switch self {
        case .default, .git, .cloud: return "SFMono-Light"
        case .icon: return "SFMono-Regular"
        case .colorful: return "SFMono-Medium"
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .default, .cloud, .colorful: return qFontSize
        case .git: return qFontSize - 0.5
        case .icon: return qFontSize + 0.5
        }
    }

    var textColor: Color {
        switch self {
        case .default, .icon: return .white
        case .git: return Color(r: 216, g: 255, b: 216)
        case .cloud: return Color(r: 226, g: 244, b: 255)
        case .colorful: return Color(r: 255, g: 246, b: 214)
        }
    }

    var promptColor: Color {
        switch self {
        case .default: return .white
        case .git: return .white
        case .cloud: return Color(r: 168, g: 221, b: 255)
        case .icon: return Color(r: 225, g: 225, b: 225)
        case .colorful: return Color(r: 255, g: 223, b: 106)
        }
    }

    var labelColor: Color {
        switch self {
        case .default: return .white
        case .git: return .white
        case .cloud: return Color(r: 135, g: 206, b: 250)
        case .icon: return Color(r: 190, g: 190, b: 190)
        case .colorful: return Color(r: 255, g: 126, b: 182)
        }
    }

    var accentColor: Color {
        switch self {
        case .default: return .green
        case .git: return Color(r: 49, g: 211, b: 96)
        case .cloud: return Color(r: 72, g: 185, b: 255)
        case .icon: return Color(r: 160, g: 160, b: 160)
        case .colorful: return Color(r: 255, g: 180, b: 60)
        }
    }

    var dateColor: Color {
        switch self {
        case .default: return colorDate
        case .git: return Color(r: 166, g: 255, b: 181)
        case .cloud: return Color(r: 185, g: 229, b: 255)
        case .icon: return Color(r: 220, g: 220, b: 220)
        case .colorful: return Color(r: 255, g: 214, b: 102)
        }
    }

    var conditionColor: Color {
        switch self {
        case .default: return colorCond
        case .git: return Color(r: 77, g: 255, b: 116)
        case .cloud: return Color(r: 99, g: 199, b: 255)
        case .icon: return Color(r: 244, g: 244, b: 244)
        case .colorful: return Color(r: 255, g: 218, b: 69)
        }
    }

    var temperatureColor: Color {
        switch self {
        case .default: return colorTemp
        case .git: return Color(r: 255, g: 210, b: 96)
        case .cloud: return Color(r: 119, g: 228, b: 255)
        case .icon: return Color(r: 255, g: 255, b: 255)
        case .colorful: return Color(r: 255, g: 117, b: 74)
        }
    }

    var humidityColor: Color {
        switch self {
        case .default: return colorHumi
        case .git: return Color(r: 116, g: 237, b: 159)
        case .cloud: return Color(r: 64, g: 179, b: 255)
        case .icon: return Color(r: 205, g: 205, b: 205)
        case .colorful: return Color(r: 40, g: 192, b: 255)
        }
    }

    var activeColor: Color {
        switch self {
        case .default: return colorKeep1
        case .git: return Color(r: 84, g: 255, b: 126)
        case .cloud: return Color(r: 102, g: 221, b: 255)
        case .icon: return Color(r: 235, g: 235, b: 235)
        case .colorful: return Color(r: 0, g: 210, b: 255)
        }
    }

    var standColor: Color {
        switch self {
        case .default: return colorKeep2
        case .git: return Color(r: 195, g: 255, b: 120)
        case .cloud: return Color(r: 176, g: 219, b: 255)
        case .icon: return Color(r: 176, g: 176, b: 176)
        case .colorful: return Color(r: 187, g: 132, b: 255)
        }
    }

    var stepColor: Color {
        switch self {
        case .default: return colorStep
        case .git: return Color(r: 94, g: 239, b: 122)
        case .cloud: return Color(r: 84, g: 177, b: 255)
        case .icon: return Color(r: 230, g: 230, b: 230)
        case .colorful: return Color(r: 118, g: 117, b: 255)
        }
    }

    var caloriesColor: Color {
        switch self {
        case .default: return colorKcal
        case .git: return Color(r: 255, g: 179, b: 79)
        case .cloud: return Color(r: 255, g: 199, b: 102)
        case .icon: return Color(r: 220, g: 220, b: 220)
        case .colorful: return Color(r: 255, g: 91, b: 73)
        }
    }

    var heartColor: Color {
        switch self {
        case .default: return colorHR
        case .git: return Color(r: 255, g: 116, b: 132)
        case .cloud: return Color(r: 255, g: 140, b: 180)
        case .icon: return Color(r: 245, g: 245, b: 245)
        case .colorful: return Color(r: 255, g: 75, b: 132)
        }
    }
}

func selectedFaceTheme(userDefaults: UserDefaults? = qUserdefaults) -> TermiFaceTheme {
    guard let rawValue = userDefaults?.string(forKey: qFaceThemeKey),
          let theme = TermiFaceTheme(rawValue: rawValue) else {
        return .default
    }

    return theme
}

func saveSelectedFaceTheme(_ theme: TermiFaceTheme, userDefaults: UserDefaults? = qUserdefaults) {
    userDefaults?.set(theme.rawValue, forKey: qFaceThemeKey)
    userDefaults?.synchronize()
}

enum TermiFaceAnimation: String, CaseIterable, Identifiable {
    case dotLine
    case matrixText
    case pacman
    case terminalCursor
    case commandLoader
    case signalSweep
    case none

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .dotLine: return "Dot Line"
        case .matrixText: return "Matrix Text"
        case .pacman: return "Pacman"
        case .terminalCursor: return "Terminal Cursor"
        case .commandLoader: return "Command Loader"
        case .signalSweep: return "Signal Sweep"
        case .none: return "No Animation"
        }
    }

    var systemImage: String {
        switch self {
        case .dotLine: return "ellipsis"
        case .matrixText: return "textformat.123"
        case .pacman: return "circle.lefthalf.filled"
        case .terminalCursor: return "cursorarrow"
        case .commandLoader: return "terminal"
        case .signalSweep: return "waveform.path"
        case .none: return "eye.slash"
        }
    }
}

func selectedFaceAnimation(userDefaults: UserDefaults? = qUserdefaults) -> TermiFaceAnimation {
    guard let rawValue = userDefaults?.string(forKey: qFaceAnimationKey),
          let animation = TermiFaceAnimation(rawValue: rawValue) else {
        return .dotLine
    }

    return animation
}

func saveSelectedFaceAnimation(_ animation: TermiFaceAnimation, userDefaults: UserDefaults? = qUserdefaults) {
    userDefaults?.set(animation.rawValue, forKey: qFaceAnimationKey)
    userDefaults?.synchronize()
}

let qGitThemeBranchName = "master"

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

func termiFaceLineHeightWeight(_ line: TermiFaceLine, theme: TermiFaceTheme) -> CGFloat {
    theme == .git && line == .promptNow ? 2 : 1
}
