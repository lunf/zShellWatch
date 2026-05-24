//
//  WatchFaceRendering.swift
//  TermiWatchWidget
//

import SwiftUI
import WidgetKit

struct FaceDataSnapshot {
    var weather: WeatherViewInfo
    var health: HealthInfo

    init(weather: WeatherViewInfo = WeatherViewInfo(), health: HealthInfo = HealthInfo()) {
        self.weather = weather
        self.health = health
    }
}

struct WatchFaceRenderRequest {
    let context: TimelineProviderContext?
    let snapshot: FaceDataSnapshot
    let configuration: WatchFaceConfiguration
}

protocol WatchFaceRendering {
    associatedtype Body: View

    @ViewBuilder
    func render(_ request: WatchFaceRenderRequest) -> Body
}

struct TerminalWatchFaceRenderer: WatchFaceRendering {
    func render(_ request: WatchFaceRenderRequest) -> some View {
        TermiFaceView(
            context: request.context,
            snapshot: request.snapshot,
            configuration: request.configuration
        )
    }
}
