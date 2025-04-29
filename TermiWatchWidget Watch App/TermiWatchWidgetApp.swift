//
//  WatchKitAppApp.swift
//  WatchKitApp Watch App
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI
import WidgetKit

@main
struct TermiWatchWidgetApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var viewModel = QTermiViewModel()
    @State var imageIndex = 1
    let userdefaults = UserDefaults.init(suiteName: qGroupBundleID)
    let session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            TabView{
                ContentView(viewModel: viewModel)
                    
                VStack {
                        
                    Button(LocalizedStringKey("Set Default BG"), action: setDefaultWidgetBG).frame(width: 200,height: 50).background(.brown).foregroundStyle(.black).border(.black, width: 1).cornerRadius(5)

                    Button(LocalizedStringKey("Set Custom BG"), action: setCustomWidgetBG).frame(width: 200,height: 50).background(.orange).foregroundStyle(.black).border(.black, width: 1).cornerRadius(5)

                }
            }.tabViewStyle(.verticalPage)
        }
        
//  如果这里报错，要兼容iOS17以下，使用下面被注释的内容
//  If an error is reported here, it should be compatible with iOS17 or below, and true should be changed to false

//#if true
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .active:
                print("📲 active")
                
                WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget" )
                WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget" )

                viewModel.updateModel()
                
//                motionViewModel.startMotionUpdates()
            case .inactive:
                print("📲 inactive")
            case .background:
                print("📲 background")
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
    
    func setCustomWidgetBG() {
        if let customImageKey = userdefaults?.string(forKey: qCustomImageKey) {
            let weatherImage = customImageKey + "_1.png"
            let healthImage = customImageKey + "_2.png"
            userdefaults?.setValue(weatherImage, forKey: qWeatherImageKey)
            userdefaults?.setValue(healthImage, forKey: qHealthImageKey)
            
            viewModel.updateModel()
            
            WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget" )
            WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget" )
        }
        if let customSmallImage = userdefaults?.string(forKey: qCustomLeftTopImageKey) {

            userdefaults?.setValue(customSmallImage, forKey: qLeftTopImageKey)
            
            WidgetCenter.shared.reloadTimelines(ofKind: "CircularWidget" )
        }
        
        imageIndex = -1
    }
    func setDefaultWidgetBG() {
        imageIndex+=2
        if(imageIndex>qBGImageCount){
            imageIndex = 1;
        }
        let weatherImage = qBGImageNamePre + String(imageIndex);
        let healthImage = qBGImageNamePre + String(imageIndex+1);
        userdefaults?.setValue(weatherImage, forKey: qWeatherImageKey)
        userdefaults?.setValue(healthImage, forKey: qHealthImageKey)
        
        userdefaults?.setValue(nil, forKey: qLeftTopImageKey)

        viewModel.updateModel()
        
        WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget" )
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget" )
        WidgetCenter.shared.reloadTimelines(ofKind: "CircularWidget" )
    }
}

#Preview {
    
    VStack{
        Text("100")
        let img = UIImage(named: "100")!

        Image(uiImage: img).frame(width: 100, height: 100, alignment: .center).backgroundStyle(.white).foregroundStyle(.red)

    }
}
