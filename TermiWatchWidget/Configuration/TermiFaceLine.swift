//
//  TermiFaceLine.swift
//  TermiWatchWidget
//

import Foundation
import SwiftUI

enum TermiFaceLine: String, CaseIterable, Identifiable, Hashable, Codable {
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

func termiFaceLineHeightWeight(_ line: TermiFaceLine, theme: TermiFaceTheme) -> CGFloat {
    theme == .git && line == .promptNow ? 2 : 1
}
