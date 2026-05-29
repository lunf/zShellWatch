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

struct BinaryWatchFaceRenderer: WatchFaceRendering {
    func render(_ request: WatchFaceRenderRequest) -> some View {
        TimelineView(.periodic(from: Date(), by: 1)) { timeline in
            BinaryWatchFaceView(date: timeline.date, theme: request.configuration.theme)
        }
    }
}

struct SelectedWatchFaceRenderer: WatchFaceRendering {
    private let terminalRenderer = TerminalWatchFaceRenderer()
    private let binaryRenderer = BinaryWatchFaceRenderer()

    @ViewBuilder
    func render(_ request: WatchFaceRenderRequest) -> some View {
        switch request.configuration.theme {
        case .binary:
            binaryRenderer.render(request)
        case .default, .git, .cloud, .icon, .colorful:
            terminalRenderer.render(request)
        }
    }
}
