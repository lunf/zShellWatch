//
//  WeatherWidgetEntryView.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/16.
//

import SwiftUI
import WidgetKit
#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

private struct TermiFaceThemeKey: EnvironmentKey {
    static let defaultValue: TermiFaceTheme = .default
}

extension EnvironmentValues {
    var termiFaceTheme: TermiFaceTheme {
        get { self[TermiFaceThemeKey.self] }
        set { self[TermiFaceThemeKey.self] = newValue }
    }
}

struct WeatherViewInfo {
    let current: QWeather
    let after1Hours: QWeather
    let alert: String
    var dateText : String? = nil
    var bgImage: String? = nil

    init(current: QWeather, after1Hours: QWeather, alert: String, dateText: String?) {
        let userdefaults = qUserdefaults

        self.dateText = dateText
        self.current = current
        self.after1Hours = after1Hours
        self.alert = alert
        self.bgImage = nil
        if let imageName = userdefaults?.string(forKey: qWeatherImageKey) {
            if let path = FileManager.default.getShareImagePath(imageName: imageName) {
                self.bgImage = path
            }
        }
    }
    
    init(current: QWeather, after1Hours: QWeather, alert: String) {
        self.init(current: current, after1Hours: after1Hours, alert: alert, dateText: nil)
    }
    
    init(){
        self.init(current: QWeather(), after1Hours: QWeather(), alert: "" )
    }
}


struct WeatherRectangularView : View {
    let context: TimelineProviderContext?
    var weather: WeatherViewInfo
    
    let font = Font.system(size: qFontSize)
    let smallFont = Font.system(size: qFontSize-2)

    var body: some View{
        let rowHeight = ((context?.displaySize.height ?? qRowHeight*5) / 5.0) + 0.5
        
        VStack(alignment: .leading,spacing: 0) {
            HStack {
                if((weather.dateText != nil) && weather.dateText!.count > 0){
                    MyText("[DATE]",fontSize: qFontSize+0.5)
                    MyText(weather.dateText!).frame(maxWidth: .infinity, alignment: .leading).minimumScaleFactor(0.8).foregroundStyle(colorDate)
                }else{
                    MyText("\(terminalName())@\(machineName()):~ $ now").frame(maxWidth: .infinity, alignment: .leading)
                }
            }.frame(height: rowHeight)
            if(weather.alert.count>0){
                HStack {
                    MyText("[ALER]",fontSize: qFontSize+0.5)
                    Image(systemName: "exclamationmark.triangle").frame(width: 16).imageScale(.small).foregroundStyle(colorAlert1).minimumScaleFactor(0.8)
                    Text(weather.alert).font(font).foregroundStyle(colorAlert1)
                }.frame(height: rowHeight)
            }
            HStack {
                MyText("[CURR]").kerning(-0.2)
                WXImage(wxIcon: weather.current.symbol).foregroundStyle(color: colorCond)
                Text(weather.current.condition).font(font).frame( maxWidth: .infinity,alignment: .leading).foregroundStyle(colorCond).minimumScaleFactor(0.8)
            }.frame(height: rowHeight)
            
            HStack {
                MyText("[TEMP]")
                Image(systemName: "thermometer.transmission").frame(width: 15).imageScale(.small).foregroundStyle(colorTemp)
                let temp = weather.current.temperature
                HStack(spacing: 0){
                    MyText(temp.value)
                    MyText(temp.unit)
                }.foregroundStyle(colorTemp)
            }.frame(height: rowHeight)
            
            HStack {
                MyText("[HUMI]",fontSize: qFontSize+0.5).kerning(-0.1)
                Image(systemName: "humidity").frame(width: 15).imageScale(.small).foregroundStyle(colorHumi)
                Text(weather.current.humidity).font(font).frame( maxWidth: .infinity,alignment: .leading).foregroundStyle(colorHumi).minimumScaleFactor(0.8)
            }.frame(height: rowHeight)
            
            if(weather.alert.count==0){
                HStack {
                    MyText("[NEXT]").kerning(0.1)
                    HStack{
                        WXImage(wxIcon: weather.after1Hours.symbol).foregroundStyle(color: colorCond)
                        Text(weather.after1Hours.condition).font(smallFont).frame(alignment: .leading).foregroundStyle(colorCond)
                        Text("\(weather.after1Hours.temperature.value)\(weather.after1Hours.temperature.unit)").font(smallFont).foregroundStyle(colorTemp)
                        Text(weather.after1Hours.humidity).font(smallFont).foregroundStyle(colorHumi)
                    }.minimumScaleFactor(0.6)
                }.frame(height: rowHeight)
            }
        }
#if os(watchOS)
        .background(Image(contentsOf:  weather.bgImage ?? "")?.resizable()
            .aspectRatio(contentMode: .fill).opacity(0.35))
#else
        .background(Image(contentsOf:  weather.bgImage ?? "")?.resizable()
            .aspectRatio(contentMode: .fit).opacity(0.35))
#endif
    }
}


struct HealthRectangularView : View {
    let context: TimelineProviderContext?
    var health: HealthInfo

    
    var body: some View {
        let rowHeight = ((context?.displaySize.height ?? qRowHeight*5) / 5.0) + 0.5

        VStack(alignment: .leading,spacing: 0) {
            HStack{
                MyText("[KEEP]")
                Image(systemName: "figure.run").imageScale(.small).foregroundStyle(colorKeep1)
                MyText("\(health.excerciseTime)").foregroundStyle(colorKeep1)
                Image(systemName: "figure.stand").imageScale(.small).foregroundStyle(colorKeep2)
                MyText("\(health.standHours)").foregroundStyle(colorKeep2)
            }.frame(height: rowHeight)
            
            HStack {
                MyText("[STEP]")
                Image(systemName: "figure.walk").imageScale(.small).foregroundStyle(colorStep)
                MyText("\(health.steps)").foregroundStyle(colorStep)
            }.frame(height: rowHeight)
            
            HStack {
                MyText("[KCAL]", fontSize: qFontSize-0.5)
                Image(systemName: "flame").imageScale(.small).foregroundStyle(colorKcal)
                MyText("\(health.excercise)").foregroundStyle(colorKcal)
            }.frame(height: rowHeight)
            
            HStack {
                MyText("[L_HR]")
                Image(systemName: "heart.circle").imageScale(.small).foregroundStyle(colorHR)
                HStack(spacing: 2){
                    MyText("\(health.heartRate)").foregroundStyle(colorHR)
                    MyText("bpm",fontSize: 10).frame(alignment: .leading)
                }
                Image(systemName: "bolt.heart").imageScale(.small).foregroundStyle(health.hrv.color)
                HStack(spacing: 2){
                    MyText("\(health.hrv.hrv)").foregroundStyle(health.hrv.color)
                    MyText("ms",fontSize: 10).frame(alignment: .leading).lineSpacing(0)
                }
            }.frame(height: rowHeight)
            
            HStack {
                MyText("\(terminalName())@\(machineName()):~ $ ").frame(maxWidth: .infinity, alignment: .leading)
            }.frame(height: rowHeight)
        }
#if os(watchOS)
        .background(Image(contentsOf: health.bgImage ?? "")?.resizable()
            .aspectRatio(contentMode: .fill).opacity(0.35))
#else
        .background(Image(contentsOf: health.bgImage ?? "")?.resizable()
            .aspectRatio(contentMode: .fit).opacity(0.35))
#endif
    }
}

struct TermiFaceView: View {
    let context: TimelineProviderContext?
    var weather: WeatherViewInfo
    var health: HealthInfo
    var lines: [TermiFaceLine] = selectedFaceLines()
    var theme: TermiFaceTheme = selectedFaceTheme()

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            let rowHeight = faceBaseRowHeight()

            VStack(alignment: .leading, spacing: qFaceRowSpacing) {
                ForEach(lines) { line in
                    faceRow(line, date: timeline.date)
                        .frame(height: rowHeight * termiFaceLineHeightWeight(line, theme: theme))
                }
            }
            .padding(.top, qFacePaddingTop)
            .padding(.horizontal, qFacePaddingHorizontal)
            .padding(.bottom, qFacePaddingBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .environment(\.termiFaceTheme, theme)
            .background {
                if let backgroundImagePath, let image = Image(contentsOf: backgroundImagePath) {
                    image
                        .resizable()
                        .scaledToFill()
                        .opacity(0.35)
                }
            }
            .clipped()
        }
    }

    private var backgroundImagePath: String? {
        let userDefaults = qUserdefaults
        if let faceImageName = userDefaults?.string(forKey: qFaceImageKey),
           let faceImagePath = FileManager.default.getShareImagePath(imageName: faceImageName) {
            return faceImagePath
        }

        return weather.bgImage ?? health.bgImage
    }

    private func faceBaseRowHeight() -> CGFloat {
        let defaultHeight = qRowHeight + 0.5
        let totalLineWeight = lines.reduce(CGFloat(0)) { $0 + termiFaceLineHeightWeight($1, theme: theme) }

        guard let displayHeight = context?.displaySize.height, totalLineWeight > 0 else {
            return defaultHeight
        }

        let totalSpacing = CGFloat(max(0, lines.count - 1)) * qFaceRowSpacing
        let verticalPadding = qFacePaddingTop + qFacePaddingBottom
        return ((displayHeight - verticalPadding - totalSpacing) / totalLineWeight) + 0.5
    }

    @ViewBuilder
    private func faceRow(_ line: TermiFaceLine, date: Date) -> some View {
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
    private func faceLineTitle(_ text: String, line: TermiFaceLine, fontSize: CGFloat? = nil, kerning: CGFloat = 0) -> some View {
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
    private func promptRow(command: String?) -> some View {
        if theme == .cloud {
            HStack(spacing: 4) {
                MyText("\(terminalName())@\(machineName())", color: theme.promptColor)
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
                MyText("\(terminalName())@\(machineName())", color: theme.promptColor)
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
                MyText("\(terminalName())@\(machineName())", color: theme.promptColor)
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
                    MyText("\(terminalName())@\(machineName()):~ ", color: theme.promptColor)
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
                MyText("\(terminalName())@\(machineName()):~ ", color: theme.promptColor)
                Text("(\(qGitThemeBranchName))")
                    .font(gitBranchFont)
                    .foregroundStyle(.cyan)
                MyText(" $ ", color: theme.promptColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            MyText("\(terminalName())@\(machineName()):~ $\(command.map { " \($0)" } ?? " ")", color: theme.promptColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func lineColor(for line: TermiFaceLine, fallback: Color) -> Color {
        guard theme == .git else {
            return fallback
        }

        return gitLineColor(for: line)
    }

    private var gitBranchFont: Font {
        .system(size: theme.fontSize, weight: .bold, design: .monospaced)
    }

    private var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    private func gitNumberText(_ text: String, line: TermiFaceLine, fontSize: CGFloat? = nil, color: Color) -> some View {
        if shouldShowGitBadge(text, line: line) {
            HStack(spacing: 2) {
                Image(systemName: gitBadgeIconName(for: line, text: text))
                    .font(.system(size: 7, weight: .bold))
                Text(text)
                    .font(Font.custom(theme.fontName, size: fontSize ?? max(theme.fontSize - 1, 9)))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Capsule().fill(.red))
            .fixedSize(horizontal: true, vertical: true)
        } else if let fontSize {
            MyText(text, fontSize: fontSize, color: color)
        } else {
            MyText(text, color: color)
        }
    }

    private func shouldShowGitBadge(_ text: String, line: TermiFaceLine) -> Bool {
        theme == .git && gitColorIndex(for: line) == 1 && text.contains { $0.isNumber }
    }

    private func gitBadgeIconName(for line: TermiFaceLine, text: String) -> String {
        let fiveMinuteBucket = Int(Date().timeIntervalSinceReferenceDate / 300)
        let seedText = "\(line.rawValue)|\(text)"
        let seed = seedText.unicodeScalars.reduce(fiveMinuteBucket) { result, scalar in
            (result &* 31) &+ Int(scalar.value)
        }

        return abs(seed) % 2 == 0 ? "plus.circle.fill" : "minus.circle.fill"
    }

    private func iconLineColor(for line: TermiFaceLine, fallback: Color) -> Color {
        guard theme == .git else {
            return fallback
        }

        return gitLineColor(for: line)
    }

    private func gitLineColor(for line: TermiFaceLine) -> Color {
        gitColor(for: gitColorIndex(for: line))
    }

    private func gitColor(for index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .red
        default: return .white
        }
    }

    private func gitColorIndex(for line: TermiFaceLine) -> Int {
        let fiveMinuteBucket = Int(Date().timeIntervalSinceReferenceDate / 300)
        let seed = line.rawValue.unicodeScalars.reduce(fiveMinuteBucket) { result, scalar in
            (result &* 31) &+ Int(scalar.value)
        }

        return abs(seed) % 3
    }

    private func timeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func batteryText() -> String {
#if os(watchOS)
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        let batteryLevel = device.batteryLevel
#elseif os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
#else
        let batteryLevel: Float = -1
#endif
        guard batteryLevel >= 0 else {
            return "--%"
        }

        return "\(Int(batteryLevel * 100))%"
    }
}

struct SmallCircularView : View {
    var image: String?
    var text : String?

    var body: some View {
        if let image = image{
            Image(contentsOf: image)?.resizable()
        }else{
            Text(text ?? "Q")
        }
    }
}



struct MyText: View {
    let text: String
    let fontSize: CGFloat?
    let color: Color?
    @Environment(\.termiFaceTheme) private var theme

    init(_ text: String) {
        self.text = text
        self.fontSize = nil
        self.color = nil
    }
    
    init(_ text: String, fontSize: CGFloat, color: Color? = nil){
        self.text = text
        self.fontSize = fontSize
        self.color = color
    }

    init(_ text: String, color: Color){
        self.text = text
        self.fontSize = nil
        self.color = color
    }
    
    private var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [
                .red,
                .orange,
                .yellow,
                .green,
                .cyan,
                .blue,
                .purple
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    var body: some View{
        if theme == .cloud {
            Text(text)
                .font(Font.custom(theme.fontName, size: fontSize ?? theme.fontSize))
                .foregroundStyle(rainbowGradient)
                .frame(alignment: .leading)
        } else {
            Text(text)
                .font(Font.custom(theme.fontName, size: fontSize ?? theme.fontSize))
                .foregroundStyle(color ?? theme.textColor)
                .frame(alignment: .leading)
        }
    }

}

#Preview(body: {
    
    VStack(alignment: .leading, spacing: 1) {
              
        WeatherRectangularView(context: nil, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-11℃",humidity: "50%"),alert: "", dateText: "Weekend"))
        
        HealthRectangularView(context: nil, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv:50)))
    }
    
})
