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
    @State private var storedFaceLines = selectedFaceLines()
    @State private var storedTheme = selectedFaceTheme()

    init(viewModel: QTermiViewModel, faceLines: [TermiFaceLine]? = nil, theme: TermiFaceTheme? = nil) {
        self.viewModel = viewModel
        self.configuredFaceLines = faceLines
        self.configuredTheme = theme
    }

    var body: some View {
        TermiFaceView(context: nil, weather: viewModel.weather, health: viewModel.health, lines: configuredFaceLines ?? storedFaceLines, theme: configuredTheme ?? storedTheme)
            .persistentSystemOverlays(.hidden)
            .onReceive(NotificationCenter.default.publisher(for: .watchSessionDidUpdateConfiguration)) { _ in
                storedFaceLines = selectedFaceLines()
                storedTheme = selectedFaceTheme()
            }
    }
}


#Preview {
    ContentView(viewModel: QTermiViewModel())
}
