//
//  WatchKitAppApp.swift
//  WatchKitApp Watch App
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI
import OSLog

private let watchAppLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "WatchApp")

@main
struct TermiWatchWidgetApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var viewModel = QTermiViewModel()
    @State private var didRunInitialRefresh = false
    let session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onReceive(NotificationCenter.default.publisher(for: .watchSessionDidUpdateConfiguration)) { _ in
                    viewModel.updateModel()
                }
        }
        
//  If this reports an error, use the commented code below to support iOS 17 and earlier.
//  If an error is reported here, it should be compatible with iOS17 or below, and true should be changed to false

//#if true
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .active:
                watchAppLogger.debug("Active")
                refreshAfterFirstFrame()
                
//                motionViewModel.startMotionUpdates()
            case .inactive:
                watchAppLogger.debug("Inactive")
            case .background:
                watchAppLogger.debug("Background")
            @unknown default: break
            }
        }
        
//#else
//        .onChange(of: scenePhase) { phase in
//
//            if(phase == .active){
//                viewModel.updateModel()
//                WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget" )
//                WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget" )
//            }
//        }
//#endif
    }

    private func refreshAfterFirstFrame() {
        guard didRunInitialRefresh else {
            didRunInitialRefresh = true
            Task { @MainActor in
                await Task.yield()
                viewModel.updateModel()
            }
            return
        }

        viewModel.updateModel()
    }
}

#Preview {
    
    VStack{
        Text("100")
        let img = UIImage(named: "100")!

        Image(uiImage: img).frame(width: 100, height: 100, alignment: .center).backgroundStyle(.white).foregroundStyle(.red)

    }
}
