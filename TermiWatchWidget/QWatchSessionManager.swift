//
//  QWatchSessionManager.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2025/2/24.
//

import WatchConnectivity
import OSLog
import WidgetKit

private let watchSessionLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "WatchSession")
private let watchSessionSyncCommandKey = "syncCommand"
private let watchSessionSyncSettingsCommand = "syncSettings"
private let watchSessionResetBackgroundsCommand = "resetBackgrounds"

extension Notification.Name {
    static let watchSessionDidUpdateConfiguration = Notification.Name("watchSessionDidUpdateConfiguration")
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchSessionManager()
    let userdefaults = qUserdefaults

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
        
    func sendImage(images: [String: URL]){
        guard WCSession.isSupported() else { return }

        for (iKey,iValue) in images{
            let name = ["name" : iKey]
            WCSession.default.transferFile(iValue, metadata: name)
        }
    }

    func syncSettingsToWatch() {
        var message: [String: Any] = [watchSessionSyncCommandKey: watchSessionSyncSettingsCommand]

        if let userName = userdefaults?.string(forKey: qUserNameKey) {
            message[qUserNameKey] = userName
        }

        if let machineName = userdefaults?.string(forKey: qMachineNameKey) {
            message[qMachineNameKey] = machineName
        }

        if let faceImage = userdefaults?.string(forKey: qFaceImageKey) {
            message[qFaceImageKey] = faceImage
        }

        if let faceLineOrder = userdefaults?.stringArray(forKey: qFaceLineOrderKey) {
            message[qFaceLineOrderKey] = faceLineOrder
        }

        sendApplicationContext(message)
        sendMessage(message: message)
    }

    func resetWatchBackgrounds() {
        let message: [String: Any] = [watchSessionSyncCommandKey: watchSessionResetBackgroundsCommand]
        sendApplicationContext(message)
        sendMessage(message: message)
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        watchSessionLogger.info("Received file: \(String(describing: file.metadata), privacy: .public)")
        let key = file.metadata?["name"] as? String
        let path = FileManager.default.saveRecivedImage(srcURL: file.fileURL)
        if((key != nil) && (path != nil)){
            userdefaults?.setValue(path, forKey: key! );
            
            if(path?.contains("_") == true){
                let custom = path?.components(separatedBy: "_").first
                userdefaults?.setValue(custom, forKey: qCustomImageKey)
            }
            userdefaults?.synchronize()
            reloadWidgetTimelines()
        }
    }
    
    func sendData(data: Data){
        if WCSession.default.isReachable {
         
            WCSession.default.sendMessageData(data, replyHandler: nil) { error in
                watchSessionLogger.error("Error sending messageData to Apple Watch: \(error.localizedDescription, privacy: .public)")
            }
            
        } else {
            watchSessionLogger.warning("WCSession is not reachable.")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        watchSessionLogger.info("Received messageData: \(messageData.count, privacy: .public)")

      
    }
    
    // Send message
    func sendMessage(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                watchSessionLogger.error("Error sending message to Apple Watch: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            watchSessionLogger.warning("WCSession is not reachable.")
        }
    }
    
    // Received message
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        watchSessionLogger.info("Received message: \(String(describing: message), privacy: .public)")
        applySettings(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        watchSessionLogger.info("Received application context: \(String(describing: applicationContext), privacy: .public)")
        applySettings(applicationContext)
    }
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        watchSessionLogger.info("Session did become inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        watchSessionLogger.info("Session did deactivate.")
    }
#endif

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            watchSessionLogger.error("Session activation failed with error: \(error.localizedDescription, privacy: .public)")
        } else {
            watchSessionLogger.info("Session activated with state: \(String(describing: activationState), privacy: .public)")
        }
    }

    private func sendApplicationContext(_ message: [String: Any]) {
        guard WCSession.isSupported() else { return }

        do {
            try WCSession.default.updateApplicationContext(message)
        } catch {
            watchSessionLogger.error("Error updating application context: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applySettings(_ message: [String: Any]) {
        if let userName = message[qUserNameKey] as? String {
            userdefaults?.set(userName, forKey: qUserNameKey)
        }

        if let machineName = message[qMachineNameKey] as? String {
            userdefaults?.set(machineName, forKey: qMachineNameKey)
        }

        if let faceLineOrder = message[qFaceLineOrderKey] as? [String] {
            userdefaults?.set(faceLineOrder, forKey: qFaceLineOrderKey)
        }

        if let faceImage = message[qFaceImageKey] as? String {
            userdefaults?.set(faceImage, forKey: qFaceImageKey)
        }

        if let command = message[watchSessionSyncCommandKey] as? String,
           command == watchSessionResetBackgroundsCommand {
            userdefaults?.setValue(nil, forKey: qWeatherImageKey)
            userdefaults?.setValue(nil, forKey: qHealthImageKey)
            userdefaults?.setValue(nil, forKey: qFaceImageKey)
            userdefaults?.setValue(nil, forKey: qLeftTopImageKey)
        }

        userdefaults?.synchronize()
        reloadWidgetTimelines()
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "CircularWidget")

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .watchSessionDidUpdateConfiguration, object: nil)
        }
    }
}
