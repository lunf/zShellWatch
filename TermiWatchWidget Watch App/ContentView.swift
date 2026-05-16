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
    @State private var storedFaceLines = selectedFaceLines()

    init(viewModel: QTermiViewModel, faceLines: [TermiFaceLine]? = nil) {
        self.viewModel = viewModel
        self.configuredFaceLines = faceLines
    }

    var body: some View {
        TermiFaceView(context: nil, weather: viewModel.weather, health: viewModel.health, lines: configuredFaceLines ?? storedFaceLines)
            .persistentSystemOverlays(.hidden)
            .onReceive(NotificationCenter.default.publisher(for: .watchSessionDidUpdateConfiguration)) { _ in
                storedFaceLines = selectedFaceLines()
            }
    }
}


#Preview {
    ContentView(viewModel: QTermiViewModel())
}
