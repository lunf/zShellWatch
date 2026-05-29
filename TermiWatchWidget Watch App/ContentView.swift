//
//  ContentView.swift
//  WatchKitApp Watch App
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI

struct ContentView: View {
    let viewModel: QTermiViewModel
    let configuredFaceLines: [TermiFaceLine]?
    let configuredTheme: TermiFaceTheme?
    let configuredAnimation: TermiFaceAnimation?
    @State private var storedFaceLines = selectedFaceLines()
    @State private var storedTheme = selectedFaceTheme()
    @State private var storedAnimation = selectedFaceAnimation()
    @State private var storedConfiguration = FaceSettingsStore().loadConfiguration()
    private let renderer = SelectedWatchFaceRenderer()

    init(viewModel: QTermiViewModel, faceLines: [TermiFaceLine]? = nil, theme: TermiFaceTheme? = nil, animation: TermiFaceAnimation? = nil) {
        self.viewModel = viewModel
        self.configuredFaceLines = faceLines
        self.configuredTheme = theme
        self.configuredAnimation = animation
    }

    var body: some View {
        renderer.render(
            WatchFaceRenderRequest(
                context: nil,
                snapshot: viewModel.snapshot,
                configuration: activeConfiguration
            )
        )
            .persistentSystemOverlays(.hidden)
            .onReceive(NotificationCenter.default.publisher(for: .watchSessionDidUpdateConfiguration)) { _ in
                storedFaceLines = selectedFaceLines()
                storedTheme = selectedFaceTheme()
                storedAnimation = selectedFaceAnimation()
                storedConfiguration = FaceSettingsStore().loadConfiguration()
            }
    }

    private var activeConfiguration: WatchFaceConfiguration {
        WatchFaceConfiguration(
            terminalUser: storedConfiguration.terminalUser,
            machineName: storedConfiguration.machineName,
            lines: configuredFaceLines ?? storedFaceLines,
            theme: configuredTheme ?? storedTheme,
            animation: configuredAnimation ?? storedAnimation
        )
    }
}


#Preview {
    ContentView(viewModel: QTermiViewModel())
}
