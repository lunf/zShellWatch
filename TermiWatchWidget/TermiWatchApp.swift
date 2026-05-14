//
//  ViewController.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI
import PhotosUI
import ClockKit

@main
struct TermiWatch: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var viewModel = QTermiViewModel()
    @State var imageIndex = 1
    let userdefaults = UserDefaults.init(suiteName: qGroupBundleID)
    let session = WatchSessionManager.shared
    @State private var selectedBGItem: [PhotosPickerItem] = []
    @State private var selectedSmallItem: [PhotosPickerItem] = []
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State var userName = terminalName()

#if targetEnvironment(simulator)
#else
    let locationMgr = WidgetLocationManager()
#endif

    var body: some Scene {
        WindowGroup {
            VStack{
                Spacer()
                ContentView(viewModel: viewModel)
                .onTapGesture {
                    imageIndex+=2
                    if(imageIndex>qBGImageCount){
                        imageIndex = 1;
                    }

                    let weatherImage = qBGImageNamePre + String(imageIndex);
                    let healthImage = qBGImageNamePre + String(imageIndex+1);
                    userdefaults?.setValue(weatherImage, forKey: qWeatherImageKey)
                    userdefaults?.setValue(healthImage, forKey: qHealthImageKey)
                    userdefaults?.synchronize()

                    viewModel.updateModel()
                }
                Spacer()

                VStack{
                    HStack{
                        Text(LocalizedStringKey("Custom User")).frame(width: 100)
                        TextField("UserName", text: $userName).foregroundStyle(.black).background(.white)
                            .frame(width: 200,height: 50).font(.system(size: 18)).submitLabel(.done).onSubmit {
                                userdefaults?.set(userName, forKey: qUserNameKey)
                                userdefaults?.synchronize()
                                viewModel.updateModel()
                                endEditing()
                            }
                    }.frame(width: 300,height: 50)

                    HStack{
                        PhotosPicker(LocalizedStringKey("Custom Left Top"), selection: $selectedSmallItem , maxSelectionCount: 1, matching: .images).frame(width: 300,height: 50).background(.orange).foregroundStyle(.black).border(.black, width: 1).cornerRadius(5)
                            .onChange(of: selectedSmallItem) {
                                Task{
                                    if let data = try await selectedSmallItem.first?.loadTransferable(type: Data.self) {
                                        print("Image data loaded: \(data.count) bytes")

                                        if let uiImage = UIImage(data: data){
                                            handleSmallImage(image: uiImage)
                                        }
                                        selectedSmallItem = []
                                    }
                                }
                            }
                    }

                    HStack{
                        PhotosPicker(LocalizedStringKey("Custom BG"), selection: $selectedBGItem , maxSelectionCount: 1, matching: .images).frame(width: 300,height: 50).background(.orange).foregroundStyle(.black).border(.black, width: 1).cornerRadius(5)
                            .onChange(of: selectedBGItem) {
                                Task{
                                    if let data = try await selectedBGItem.first?.loadTransferable(type: Data.self) {
                                        print("Image data loaded: \(data.count) bytes")

                                        if let uiImage = UIImage(data: data){
                                            handleBGImage(image: uiImage)
                                        }
                                        selectedBGItem = []
                                    }
                                }
                            }
                    }

                    HStack(alignment: .bottom, content: {

                        Button(LocalizedStringKey("Sync Watch Face"), action: addWatchFace).frame(width: 300,height: 50).background(.orange).foregroundStyle(.black).border(.black, width: 1).cornerRadius(5)

                    })
                    Spacer()
                }
            }
            .alert(LocalizedStringKey("Error"), isPresented: $isShowingError) {
                Button(LocalizedStringKey("OK"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }

        }
        //  如果这里报错，要兼容iOS17以下，true 修改为 false
        //  If an error is reported here, it should be compatible with iOS17 or below, and true should be changed to false
#if true
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .active:
                print("📲 active")
                viewModel.updateModel()

//                motionViewModel.startMotionUpdates()

            case .inactive:
                print("📲 inactive")
            case .background:
                print("📲 background")
            @unknown default: break
            }
        }
#else
        .onChange(of: scenePhase) { phase in

            if(phase == .active){
                viewModel.updateModel()
            }
        }
#endif

    }

    let library = CLKWatchFaceLibrary()

    func addWatchFace(){

        guard let url = Bundle.main.url(forResource: "TermiWatchWidget", withExtension: "watchface") else {
            showError("*** Unable to find TermiWatchWidget.watchface in the app bundle ***")
            return
        }
        library.addWatchFace(at: url) { error in
            if let error = error {
                showError("*** An error occurred: \(error.localizedDescription) ***")
            }
        }
    }

    func handleBGImage(image:UIImage){
        // max 463.2, 196.7 ,  463*400 (App)
        // max area 72112, 68904/  (Widget )
        // 460 * 156, 460 * 149

        let w = 460.0, h = 306.0, h1 = 149.0, h2 = 149.0
        var newFrame = CGRect(x: 0, y: 0, width:w, height: h)

        let imgW = image.size.width
        let imgH = image.size.height

        var dstH = h
        var dstW = dstH / imgH * imgW

        let startX = w - dstW;

        if(startX >= 0){
            newFrame.origin.x = startX
        }else{
            dstW = w
            dstH = dstW / imgW * imgH
            let startY = h - dstH

            newFrame.origin.y = startY / 2.0
        }

        let dstSize = CGSize(width: dstW, height: dstH)
        var dstImage = image.scaleTo(dstSize)

        let drawFrame = CGRect(origin: newFrame.origin, size: dstSize)
        dstImage = dstImage?.drawTo(newSize: newFrame.size, drawFrame: drawFrame)

        let frame1 = CGRect(x:0, y:0, width: w, height: h1)
        let image1 = dstImage?.cropWithCropRect(frame1)

        let frame2 = CGRect(x:0, y:h1+8, width: w, height: h2)
        let image2 = dstImage?.cropWithCropRect(frame2)

        if(image1 != nil && image2 != nil){
            let imagedata1 = image1!.pngData()!
            let imagedata2 = image2!.pngData()!

            let oldPath = userdefaults?.string(forKey: qCustomImageKey)

            // AppGroup共享文件无效，Watch和iPhone是互相隔离的，无法取得资源文件, 使用WCSession传输
            let urls = FileManager.default.saveCutsomWidgetBGImage(image1: imagedata1, image2: imagedata2, oldPath: oldPath)
            guard urls.count >= 2 else {
                showError("Unable to save custom background image.")
                return
            }

            session.sendImage(images: [qWeatherImageKey: urls[0]])
            session.sendImage(images: [qHealthImageKey: urls[1]])

            userdefaults?.setValue(urls[0].lastPathComponent, forKey: qWeatherImageKey);
            userdefaults?.setValue(urls[1].lastPathComponent, forKey: qHealthImageKey);

            let customPath = urls[0].lastPathComponent.components(separatedBy: "_").first
            userdefaults?.setValue(customPath, forKey: qCustomImageKey)

            userdefaults?.synchronize()

            viewModel.updateModel()
        }
    }

    func handleSmallImage(image:UIImage){
        // max 463.2, 196.7 ,  463*400 (App)
        // max area 72112, 68904/  (Widget )
        // 460 * 156, 460 * 149

        let w = 100.0, h = 100.0;
        var newFrame = CGRect(x: 0, y: 0, width:w, height: h)

        let imgW = image.size.width
        let imgH = image.size.height

        var dstH = h
        var dstW = dstH / imgH * imgW

        let startX = w - dstW;

        if(startX >= 0){
            newFrame.origin.x = startX
        }else{
            dstW = w
            dstH = dstW / imgW * imgH
            let startY = h - dstH

            newFrame.origin.y = startY / 2.0
        }

        let dstSize = CGSize(width: dstW, height: dstH)
        var dstImage = image.scaleTo(dstSize)

        let drawFrame = CGRect(origin: newFrame.origin, size: dstSize)
        dstImage = dstImage?.drawTo(newSize: newFrame.size, drawFrame: drawFrame)


        if(dstImage != nil){
            guard let imageData = dstImage!.pngData() else {
                showError("Unable to process custom image.")
                return
            }

            let oldPath = userdefaults?.string(forKey: qCustomLeftTopImageKey)

            // AppGroup共享文件无效，Watch和iPhone是互相隔离的，无法取得资源文件, 使用WCSession传输
            if let url = FileManager.default.saveCutsomWidgetSmallImage(image: imageData, oldPath: oldPath){

                session.sendImage(images: [qLeftTopImageKey: url])

                userdefaults?.setValue(url.lastPathComponent, forKey: qLeftTopImageKey);
                userdefaults?.setValue(url.lastPathComponent, forKey: qCustomLeftTopImageKey);

                userdefaults?.synchronize()

                viewModel.updateModel()

                if(url.lastPathComponent.contains("_") == true){
                    print(" contain ____");
                }
            }
        }
    }

    func showError(_ message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            isShowingError = true
        }
    }


    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}

extension UIImage{
    func scaleTo( _ size: CGSize) -> UIImage? {
        if self.cgImage == nil { return nil }
        UIGraphicsBeginImageContext(size);
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return scaledImage;
    }
    func drawTo(newSize: CGSize, drawFrame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(newSize);
        draw(in: drawFrame)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return scaledImage;
    }

    func cropWithCropRect( _ crop: CGRect) -> UIImage? {
        let cropRect = CGRect(x: crop.origin.x * self.scale, y: crop.origin.y * self.scale, width: crop.size.width * self.scale, height: crop.size.height *  self.scale)
        if cropRect.size.width <= 0 || cropRect.size.height <= 0 {
           return nil
        }
        var image:UIImage?
        autoreleasepool{
           let imageRef: CGImage?  = self.cgImage!.cropping(to: cropRect)
           if let imageRef = imageRef {
               image = UIImage(cgImage: imageRef)
           }
        }
        return image
    }
}
