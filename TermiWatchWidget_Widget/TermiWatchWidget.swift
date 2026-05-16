//
//  MyWatchWidget.swift
//  MyWatchWidget
//
//  Created by Qianlishun on 2023/10/10.
//

import WidgetKit
import SwiftUI

@main
struct WidgetForWatchOS: WidgetBundle {
    var body: some Widget {
        WeatherWidget()
        HealthWidget()
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }.configurationDisplayName(LocalizedStringKey("Weather"))
    }

}

struct HealthWidget: Widget {
    let kind: String = "HealthWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(kind: kind, provider: HealthProvider()) { entry in
            HealthWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }.configurationDisplayName(LocalizedStringKey("Health"))
    }

}

struct WeatherProvider: TimelineProvider {

    var widgetLocationManager = WidgetLocationManager()

    func placeholder(in context: Context) -> WeatherEntry {
        return WeatherEntry(context: context, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-5℃",humidity: "50%"),alert: ""))

    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> ()) {

        let entry = WeatherEntry(context: context, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-5℃",humidity: "50%"),alert: ""))

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let formatter = getCurrentFormatter()

        widgetLocationManager.fetchLocation(handler: { location in
            Task{
                if !HFWeatherKey.isEmpty {
                    getHFWeather(location: location) { weather in
                        let entries = makeWeatherEntries(from: weather, context: context, formatter: formatter, maxCount: 12)
                        let timeline = Timeline(entries: entries, policy: .atEnd)

                        completion(timeline)
                    }
                } else if qUseWeatherKit {
                    do {
                        let weather = try await getWeather(location: location, afterHours: 6)
                        let entries = makeWeatherEntries(from: weather, context: context, formatter: formatter, maxCount: 5)
                        let timeline = Timeline(entries: entries, policy: .atEnd)

                        completion(timeline)
                    } catch {
                        completion(emptyWeatherTimeline(context: context))
                    }
                } else {
                    completion(emptyWeatherTimeline(context: context))
                }
            }
        })
    }

    private func makeWeatherEntries(from weather: WeatherInfo, context: Context, formatter: DateFormatter, maxCount: Int) -> [WeatherEntry] {
        let entryCount = min(maxCount, max(0, weather.weathers.count - 1))
        guard entryCount > 0 else {
            return [WeatherEntry(context: context, weather: WeatherViewInfo())]
        }

        return (0..<entryCount).map { index in
            let current = weather.weathers[index]
            let after1Hours = weather.weathers[index + 1]
            let alert = weather.alerts.indices.contains(index) ? weather.alerts[index] : ""
            let dateStr = formatter.noYear(from: current.date)
            let info = WeatherViewInfo(current: current, after1Hours: after1Hours, alert: alert, dateText: dateStr)

            return WeatherEntry(context: context, date: info.current.date, weather: info)
        }
    }

    private func emptyWeatherTimeline(context: Context) -> Timeline<WeatherEntry> {
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let entry = WeatherEntry(context: context, weather: WeatherViewInfo())
        return Timeline(entries: [entry], policy: .after(refresh))
    }
}

struct HealthProvider: TimelineProvider {

    var healthObserver = HealthObserver()

    func placeholder(in context: Context) -> HealthEntry {
        return HealthEntry(context: context, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv: 50)))
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> ()) {
        let entry = HealthEntry(context: context, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv: 50)))

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var refresh = Calendar.current.date(byAdding: .minute, value: healthRefreshInterval, to: Date()) ?? Date()
        if(isEveningNow()){
            refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        }
        healthObserver.getHealthInfo { health in
            let entry = HealthEntry( context: context, health: health)

            let timeline = Timeline(entries: [entry], policy: .after(refresh))

            completion(timeline)
        }
    }
    func isEveningNow() -> Bool {
       let date = Date()
       let calendar = Calendar.current
       let components = calendar.component(.hour, from: date)

       // Night range, for example 22:00 to 06:00
       return components >= 22 || components < 6
   }
}

struct CircularWidgetEntryView : View{
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        default:
            VStack{}
        }
    }
}

struct WeatherWidgetEntryView : View {
    var entry: WeatherProvider.Entry
    @Environment(\.widgetFamily) var family


    var body: some View {
        switch family {
        case .accessoryCircular:

            Text("Q")

        case .accessoryRectangular:

            WeatherRectangularView(context: entry.context, weather: entry.weather)

        default:
            VStack{}
        }
    }
}

struct HealthWidgetEntryView : View {
    var entry: HealthProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:

            Text("V")

        case .accessoryRectangular:

            HealthRectangularView(context: entry.context, health: entry.health)

        default:
            VStack{}
        }
    }
}

struct CircularEntry: TimelineEntry {
    var date: Date = Date()
    let image: String
    let string: String
    init(image: String, string: String) {
        self.image = image
        self.string = string
    }
    init(){
        self.init(image: "", string: "Q")
    }
}

struct WeatherEntry: TimelineEntry {
    let context: TimelineProviderContext?
    var date: Date = Date()
    let weather: WeatherViewInfo
}

struct HealthEntry: TimelineEntry {
    let context: TimelineProviderContext?
    var date: Date = Date()
    let health: HealthInfo
}


#Preview(as: .accessoryRectangular) {
    WeatherWidget()
} timeline: {
    WeatherEntry(context: nil, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-11℃",humidity: "50%"),alert: "High Wind Warning"))
}

#Preview(as: .accessoryRectangular) {
    HealthWidget()
} timeline: {
    HealthEntry(context: nil, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv:50)))
}
