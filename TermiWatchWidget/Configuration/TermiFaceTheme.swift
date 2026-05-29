//
//  TermiFaceTheme.swift
//  TermiWatchWidget
//

import Foundation
import SwiftUI

struct TermiFaceThemeStyle {
    let titleKey: String
    let systemImage: String
    let fontName: String
    let fontSize: CGFloat
    let textColor: Color
    let promptColor: Color
    let labelColor: Color
    let accentColor: Color
    let dateColor: Color
    let conditionColor: Color
    let temperatureColor: Color
    let humidityColor: Color
    let activeColor: Color
    let standColor: Color
    let stepColor: Color
    let caloriesColor: Color
    let heartColor: Color

    static let defaultTheme = TermiFaceThemeStyle(
        titleKey: "Default Theme",
        systemImage: "terminal",
        fontName: "SFMono-Light",
        fontSize: qFontSize,
        textColor: .white,
        promptColor: .white,
        labelColor: .white,
        accentColor: .green,
        dateColor: colorDate,
        conditionColor: colorCond,
        temperatureColor: colorTemp,
        humidityColor: colorHumi,
        activeColor: colorKeep1,
        standColor: colorKeep2,
        stepColor: colorStep,
        caloriesColor: colorKcal,
        heartColor: colorHR
    )

    static let git = TermiFaceThemeStyle(
        titleKey: "Git Theme",
        systemImage: "arrow.triangle.branch",
        fontName: "SFMono-Light",
        fontSize: qFontSize - 0.5,
        textColor: Color(r: 216, g: 255, b: 216),
        promptColor: .white,
        labelColor: .white,
        accentColor: Color(r: 49, g: 211, b: 96),
        dateColor: Color(r: 166, g: 255, b: 181),
        conditionColor: Color(r: 77, g: 255, b: 116),
        temperatureColor: Color(r: 255, g: 210, b: 96),
        humidityColor: Color(r: 116, g: 237, b: 159),
        activeColor: Color(r: 84, g: 255, b: 126),
        standColor: Color(r: 195, g: 255, b: 120),
        stepColor: Color(r: 94, g: 239, b: 122),
        caloriesColor: Color(r: 255, g: 179, b: 79),
        heartColor: Color(r: 255, g: 116, b: 132)
    )

    static let cloud = TermiFaceThemeStyle(
        titleKey: "Cloud Theme",
        systemImage: "cloud.sun",
        fontName: "SFMono-Light",
        fontSize: qFontSize,
        textColor: Color(r: 226, g: 244, b: 255),
        promptColor: Color(r: 168, g: 221, b: 255),
        labelColor: Color(r: 135, g: 206, b: 250),
        accentColor: Color(r: 72, g: 185, b: 255),
        dateColor: Color(r: 185, g: 229, b: 255),
        conditionColor: Color(r: 99, g: 199, b: 255),
        temperatureColor: Color(r: 119, g: 228, b: 255),
        humidityColor: Color(r: 64, g: 179, b: 255),
        activeColor: Color(r: 102, g: 221, b: 255),
        standColor: Color(r: 176, g: 219, b: 255),
        stepColor: Color(r: 84, g: 177, b: 255),
        caloriesColor: Color(r: 255, g: 199, b: 102),
        heartColor: Color(r: 255, g: 140, b: 180)
    )

    static let icon = TermiFaceThemeStyle(
        titleKey: "Icon Theme",
        systemImage: "app.badge",
        fontName: "SFMono-Regular",
        fontSize: qFontSize + 0.5,
        textColor: .white,
        promptColor: Color(r: 225, g: 225, b: 225),
        labelColor: Color(r: 190, g: 190, b: 190),
        accentColor: Color(r: 160, g: 160, b: 160),
        dateColor: Color(r: 220, g: 220, b: 220),
        conditionColor: Color(r: 244, g: 244, b: 244),
        temperatureColor: Color(r: 255, g: 255, b: 255),
        humidityColor: Color(r: 205, g: 205, b: 205),
        activeColor: Color(r: 235, g: 235, b: 235),
        standColor: Color(r: 176, g: 176, b: 176),
        stepColor: Color(r: 230, g: 230, b: 230),
        caloriesColor: Color(r: 220, g: 220, b: 220),
        heartColor: Color(r: 245, g: 245, b: 245)
    )

    static let colorful = TermiFaceThemeStyle(
        titleKey: "Colorful Theme",
        systemImage: "paintpalette",
        fontName: "SFMono-Medium",
        fontSize: qFontSize,
        textColor: Color(r: 255, g: 246, b: 214),
        promptColor: Color(r: 255, g: 223, b: 106),
        labelColor: Color(r: 255, g: 126, b: 182),
        accentColor: Color(r: 255, g: 180, b: 60),
        dateColor: Color(r: 255, g: 214, b: 102),
        conditionColor: Color(r: 255, g: 218, b: 69),
        temperatureColor: Color(r: 255, g: 117, b: 74),
        humidityColor: Color(r: 40, g: 192, b: 255),
        activeColor: Color(r: 0, g: 210, b: 255),
        standColor: Color(r: 187, g: 132, b: 255),
        stepColor: Color(r: 118, g: 117, b: 255),
        caloriesColor: Color(r: 255, g: 91, b: 73),
        heartColor: Color(r: 255, g: 75, b: 132)
    )

    static let binary = TermiFaceThemeStyle(
        titleKey: "Binary Theme",
        systemImage: "circle.grid.3x3.fill",
        fontName: "SFMono-Medium",
        fontSize: qFontSize,
        textColor: Color(r: 232, g: 255, b: 238),
        promptColor: Color(r: 232, g: 255, b: 238),
        labelColor: Color(r: 125, g: 220, b: 150),
        accentColor: Color(r: 0, g: 255, b: 128),
        dateColor: Color(r: 0, g: 255, b: 128),
        conditionColor: Color(r: 0, g: 255, b: 128),
        temperatureColor: Color(r: 0, g: 255, b: 128),
        humidityColor: Color(r: 0, g: 255, b: 128),
        activeColor: Color(r: 0, g: 255, b: 128),
        standColor: Color(r: 0, g: 255, b: 128),
        stepColor: Color(r: 0, g: 255, b: 128),
        caloriesColor: Color(r: 0, g: 255, b: 128),
        heartColor: Color(r: 0, g: 255, b: 128)
    )
}

enum TermiFaceTheme: String, CaseIterable, Identifiable, Codable {
    case `default`
    case git
    case cloud
    case icon
    case colorful
    case binary

    var id: String { rawValue }

    var style: TermiFaceThemeStyle {
        Self.styles[self] ?? .defaultTheme
    }

    var titleKey: String {
        style.titleKey
    }

    var systemImage: String {
        style.systemImage
    }

    var fontName: String {
        style.fontName
    }

    var fontSize: CGFloat {
        style.fontSize
    }

    var textColor: Color {
        style.textColor
    }

    var promptColor: Color {
        style.promptColor
    }

    var labelColor: Color {
        style.labelColor
    }

    var accentColor: Color {
        style.accentColor
    }

    var dateColor: Color {
        style.dateColor
    }

    var conditionColor: Color {
        style.conditionColor
    }

    var temperatureColor: Color {
        style.temperatureColor
    }

    var humidityColor: Color {
        style.humidityColor
    }

    var activeColor: Color {
        style.activeColor
    }

    var standColor: Color {
        style.standColor
    }

    var stepColor: Color {
        style.stepColor
    }

    var caloriesColor: Color {
        style.caloriesColor
    }

    var heartColor: Color {
        style.heartColor
    }

    private static let styles: [TermiFaceTheme: TermiFaceThemeStyle] = [
        .default: .defaultTheme,
        .git: .git,
        .cloud: .cloud,
        .icon: .icon,
        .colorful: .colorful,
        .binary: .binary
    ]
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

let qGitThemeBranchName = "master"

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
let colorKcal = Color(r: 238, g: 98, b: 48)
let colorHR = Color(r: 235, g: 74, b: 98)
let qRowHeight = 14.0
let qFaceRowSpacing = 3.0
let qFacePaddingTop = 20.0
let qFacePaddingHorizontal = 12.0
let qFacePaddingBottom = 12.0
let qFontSize = 13.0
