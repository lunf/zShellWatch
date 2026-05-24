//
//  TermiFaceView+Builders.swift
//  TermiWatchWidget
//

import SwiftUI

extension TermiFaceView {
    @ViewBuilder
    func faceRow(_ line: TermiFaceLine, date: Date) -> some View {
        switch line {
        case .promptNow:
            promptRow(command: "now")
        case .date:
            HStack {
                faceLineTitle("[DATE]", line: line, fontSize: qFontSize + 0.5)
                MyText(date.currentDate(), color: lineColor(for: line, fallback: theme.dateColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
            }
        case .time:
            HStack {
                faceLineTitle("[TIME]", line: line)
                Image(systemName: "clock").frame(width: 15).imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.accentColor))
                gitNumberText(timeText(from: date), line: line, color: lineColor(for: line, fallback: theme.textColor))
            }
        case .currentWeather:
            HStack {
                faceLineTitle("[CURR]", line: line, kerning: -0.2)
                WXImage(wxIcon: weather.current.symbol).foregroundStyle(color: iconLineColor(for: line, fallback: theme.conditionColor))
                MyText(weather.current.condition, fontSize: qFontSize, color: lineColor(for: line, fallback: theme.conditionColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
            }
        case .temperature:
            HStack {
                faceLineTitle("[TEMP]", line: line)
                Image(systemName: "thermometer.transmission").frame(width: 15).imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.temperatureColor))
                gitNumberText("\(weather.current.temperature.value)\(weather.current.temperature.unit)", line: line, color: lineColor(for: line, fallback: theme.temperatureColor))
            }
        case .humidity:
            HStack {
                faceLineTitle("[HUMI]", line: line, fontSize: qFontSize + 0.5, kerning: -0.1)
                Image(systemName: "humidity").frame(width: 15).imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.humidityColor))
                gitNumberText(weather.current.humidity, line: line, color: lineColor(for: line, fallback: theme.humidityColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
            }
        case .nextWeather:
            HStack {
                faceLineTitle("[NEXT]", line: line, kerning: 0.1)
                HStack {
                    WXImage(wxIcon: weather.after1Hours.symbol).foregroundStyle(color: iconLineColor(for: line, fallback: theme.conditionColor))
                    MyText(weather.after1Hours.condition, fontSize: qFontSize - 2, color: lineColor(for: line, fallback: theme.conditionColor))
                        .frame(alignment: .leading)
                    gitNumberText("\(weather.after1Hours.temperature.value)\(weather.after1Hours.temperature.unit)", line: line, fontSize: qFontSize - 2, color: lineColor(for: line, fallback: theme.temperatureColor))
                    gitNumberText(weather.after1Hours.humidity, line: line, fontSize: qFontSize - 2, color: lineColor(for: line, fallback: theme.humidityColor))
                }
                .minimumScaleFactor(0.6)
            }
        case .battery:
            HStack {
                faceLineTitle("[BATT]", line: line)
                Image(systemName: "battery.100").frame(width: 15).imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.accentColor))
                gitNumberText(batteryText(), line: line, color: lineColor(for: line, fallback: theme.accentColor))
            }
        case .rings:
            HStack {
                faceLineTitle("[RING]", line: line)
                Image(systemName: "figure.run").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.activeColor))
                gitNumberText("\(health.excerciseTime)", line: line, color: lineColor(for: line, fallback: theme.activeColor))
                Image(systemName: "figure.stand").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.standColor))
                gitNumberText("\(health.standHours)", line: line, color: lineColor(for: line, fallback: theme.standColor))
            }
        case .steps:
            HStack {
                faceLineTitle("[STEP]", line: line)
                Image(systemName: "figure.walk").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.stepColor))
                gitNumberText("\(health.steps)", line: line, color: lineColor(for: line, fallback: theme.stepColor))
            }
        case .calories:
            HStack {
                faceLineTitle("[KCAL]", line: line, fontSize: qFontSize - 0.5)
                Image(systemName: "flame").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.caloriesColor))
                gitNumberText("\(health.excercise)", line: line, color: lineColor(for: line, fallback: theme.caloriesColor))
            }
        case .heartRate:
            HStack {
                faceLineTitle("[L_HR]", line: line)
                Image(systemName: "heart.circle").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: theme.heartColor))
                HStack(spacing: 2) {
                    gitNumberText("\(health.heartRate)", line: line, color: lineColor(for: line, fallback: theme.heartColor))
                    MyText("bpm", fontSize: 10, color: lineColor(for: line, fallback: theme.heartColor)).frame(alignment: .leading)
                }
                Image(systemName: "bolt.heart").imageScale(.small).foregroundStyle(iconLineColor(for: line, fallback: health.hrv.color))
                HStack(spacing: 2) {
                    gitNumberText("\(health.hrv.hrv)", line: line, color: lineColor(for: line, fallback: health.hrv.color))
                    MyText("ms", fontSize: 10, color: lineColor(for: line, fallback: health.hrv.color)).frame(alignment: .leading).lineSpacing(0)
                }
            }
        case .prompt:
            promptRow(command: nil)
        }
    }

    @ViewBuilder
    func faceLineTitle(_ text: String, line: TermiFaceLine, fontSize: CGFloat? = nil, kerning: CGFloat = 0) -> some View {
        if theme != .icon {
            let titleColor = lineColor(for: line, fallback: theme.labelColor)
            if let fontSize {
                MyText(text, fontSize: fontSize, color: titleColor)
                    .kerning(kerning)
            } else {
                MyText(text, color: titleColor)
                    .kerning(kerning)
            }
        }
    }

    @ViewBuilder
    func promptRow(command: String?) -> some View {
        if theme == .cloud {
            HStack(spacing: 4) {
                MyText("\(terminalUser)@\(machine)", color: theme.promptColor)
                Image(systemName: "cloud.fill")
                    .imageScale(.small)
                    .foregroundStyle(theme.accentColor)
                Image(systemName: "bolt.fill")
                    .imageScale(.small)
                    .foregroundStyle(Color(r: 255, g: 218, b: 69))
                if let command {
                    MyText(command, color: theme.promptColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if theme == .icon {
            HStack(spacing: 4) {
                MyText("\(terminalUser)@\(machine)", color: theme.promptColor)
                Image(systemName: "terminal.fill")
                    .imageScale(.small)
                    .foregroundStyle(theme.accentColor)
                if let command {
                    MyText(command, color: theme.promptColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if theme == .colorful {
            HStack(spacing: 4) {
                MyText("\(terminalUser)@\(machine)", color: theme.promptColor)
                Image(systemName: "rainbow")
                    .imageScale(.small)
                    .foregroundStyle(rainbowGradient)
                if let command {
                    MyText(command, color: theme.promptColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if theme == .git, let command {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 0) {
                    MyText("\(terminalUser)@\(machine):~ ", color: theme.promptColor)
                    Text("(\(qGitThemeBranchName))")
                        .font(gitBranchFont)
                        .foregroundStyle(.cyan)
                }
                HStack(spacing: 4) {
                    MyText("➜", color: .cyan)
                    MyText(command, color: theme.promptColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if theme == .git {
            HStack(spacing: 0) {
                MyText("\(terminalUser)@\(machine):~ ", color: theme.promptColor)
                Text("(\(qGitThemeBranchName))")
                    .font(gitBranchFont)
                    .foregroundStyle(.cyan)
                MyText(" $ ", color: theme.promptColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            MyText("\(terminalUser)@\(machine):~ $\(command.map { " \($0)" } ?? " ")", color: theme.promptColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
