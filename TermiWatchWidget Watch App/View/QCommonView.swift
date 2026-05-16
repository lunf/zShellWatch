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

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            let rowHeight = faceRowHeight(lineCount: lines.count)

            VStack(alignment: .leading, spacing: qFaceRowSpacing) {
                ForEach(lines) { line in
                    faceRow(line, date: timeline.date)
                        .frame(height: rowHeight)
                }
            }
            .padding(.top, qFacePaddingTop)
            .padding(.horizontal, qFacePaddingHorizontal)
            .padding(.bottom, qFacePaddingBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private func faceRowHeight(lineCount: Int) -> CGFloat {
        let defaultHeight = qRowHeight + 0.5
        guard let displayHeight = context?.displaySize.height, lineCount > 0 else {
            return defaultHeight
        }

        let totalSpacing = CGFloat(max(0, lineCount - 1)) * qFaceRowSpacing
        let verticalPadding = qFacePaddingTop + qFacePaddingBottom
        return ((displayHeight - verticalPadding - totalSpacing) / CGFloat(lineCount)) + 0.5
    }

    @ViewBuilder
    private func faceRow(_ line: TermiFaceLine, date: Date) -> some View {
        switch line {
        case .promptNow:
            MyText("\(terminalName())@\(machineName()):~ $ now")
                .frame(maxWidth: .infinity, alignment: .leading)
        case .date:
            HStack {
                MyText("[DATE]", fontSize: qFontSize + 0.5)
                MyText(date.currentDate())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(colorDate)
            }
        case .time:
            HStack {
                MyText("[TIME]")
                Image(systemName: "clock").frame(width: 15).imageScale(.small)
                MyText(timeText(from: date))
            }
        case .currentWeather:
            HStack {
                MyText("[CURR]").kerning(-0.2)
                WXImage(wxIcon: weather.current.symbol).foregroundStyle(color: colorCond)
                Text(weather.current.condition).font(.system(size: qFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(colorCond)
                    .minimumScaleFactor(0.8)
            }
        case .temperature:
            HStack {
                MyText("[TEMP]")
                Image(systemName: "thermometer.transmission").frame(width: 15).imageScale(.small).foregroundStyle(colorTemp)
                HStack(spacing: 0) {
                    MyText(weather.current.temperature.value)
                    MyText(weather.current.temperature.unit)
                }
                .foregroundStyle(colorTemp)
            }
        case .humidity:
            HStack {
                MyText("[HUMI]", fontSize: qFontSize + 0.5).kerning(-0.1)
                Image(systemName: "humidity").frame(width: 15).imageScale(.small).foregroundStyle(colorHumi)
                Text(weather.current.humidity).font(.system(size: qFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(colorHumi)
                    .minimumScaleFactor(0.8)
            }
        case .nextWeather:
            HStack {
                MyText("[NEXT]").kerning(0.1)
                HStack {
                    WXImage(wxIcon: weather.after1Hours.symbol).foregroundStyle(color: colorCond)
                    Text(weather.after1Hours.condition).font(.system(size: qFontSize - 2)).frame(alignment: .leading).foregroundStyle(colorCond)
                    Text("\(weather.after1Hours.temperature.value)\(weather.after1Hours.temperature.unit)").font(.system(size: qFontSize - 2)).foregroundStyle(colorTemp)
                    Text(weather.after1Hours.humidity).font(.system(size: qFontSize - 2)).foregroundStyle(colorHumi)
                }
                .minimumScaleFactor(0.6)
            }
        case .battery:
            HStack {
                MyText("[BATT]")
                Image(systemName: "battery.100").frame(width: 15).imageScale(.small).foregroundStyle(.green)
                MyText(batteryText()).foregroundStyle(.green)
            }
        case .rings:
            HStack {
                MyText("[RING]")
                Image(systemName: "figure.run").imageScale(.small).foregroundStyle(colorKeep1)
                MyText("\(health.excerciseTime)").foregroundStyle(colorKeep1)
                Image(systemName: "figure.stand").imageScale(.small).foregroundStyle(colorKeep2)
                MyText("\(health.standHours)").foregroundStyle(colorKeep2)
            }
        case .steps:
            HStack {
                MyText("[STEP]")
                Image(systemName: "figure.walk").imageScale(.small).foregroundStyle(colorStep)
                MyText("\(health.steps)").foregroundStyle(colorStep)
            }
        case .calories:
            HStack {
                MyText("[KCAL]", fontSize: qFontSize - 0.5)
                Image(systemName: "flame").imageScale(.small).foregroundStyle(colorKcal)
                MyText("\(health.excercise)").foregroundStyle(colorKcal)
            }
        case .heartRate:
            HStack {
                MyText("[L_HR]")
                Image(systemName: "heart.circle").imageScale(.small).foregroundStyle(colorHR)
                HStack(spacing: 2) {
                    MyText("\(health.heartRate)").foregroundStyle(colorHR)
                    MyText("bpm", fontSize: 10).frame(alignment: .leading)
                }
                Image(systemName: "bolt.heart").imageScale(.small).foregroundStyle(health.hrv.color)
                HStack(spacing: 2) {
                    MyText("\(health.hrv.hrv)").foregroundStyle(health.hrv.color)
                    MyText("ms", fontSize: 10).frame(alignment: .leading).lineSpacing(0)
                }
            }
        case .prompt:
            MyText("\(terminalName())@\(machineName()):~ $ ")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
    let font: Font
    
    let text: String
    
    init(_ text: String) {
        self.text = text
        self.font = Font.custom("SFMono-Light", size: qFontSize)
    }
    
    init(_ text: String, fontSize: CGFloat){
        self.text = text
        self.font = Font.custom("SFMono-Light", size: fontSize)
    }
    
    var body: some View{
        Text(text).font(font).foregroundStyle(.white).frame(alignment: .leading)
    }

}

#Preview(body: {
    
    VStack(alignment: .leading, spacing: 1) {
              
        WeatherRectangularView(context: nil, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-11℃",humidity: "50%"),alert: "", dateText: "Weekend"))
        
        HealthRectangularView(context: nil, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv:50)))
    }
    
})
