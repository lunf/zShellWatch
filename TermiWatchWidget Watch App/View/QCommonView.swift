//
//  QCommonView.swift
//  TermiWatchWidget
//

import SwiftUI

#Preview(body: {
    
    VStack(alignment: .leading, spacing: 1) {
              
        WeatherRectangularView(context: nil, weather: WeatherViewInfo(current: QWeather(date: Date(), condition: "Light Rain", symbol: "cloud.rain", temperature: "20℃",humidity: "50%"), after1Hours: QWeather(date: Date()+3600,condition: "Heavy Snow", symbol: "snow", temperature: "-11℃",humidity: "50%"),alert: "", dateText: "Weekend"))
        
        HealthRectangularView(context: nil, health: HealthInfo(steps: 9999, excercise: 99, excerciseTime: 99, standHours: 99, heartRate: 60, hrv: HealthHRV(hrv:50)))
    }
    
})
