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

enum WatchSettingsSyncResult {
    case delivered(Date)
    case saved(Date, reason: String)
    case failed(Date, reason: String)
}

extension Notification.Name {
    static let watchSessionDidUpdateConfiguration = Notification.Name("watchSessionDidUpdateConfiguration")
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchSessionManager()
    let userdefaults = qUserdefaults
    private let settingsStore = FaceSettingsStore()

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

    func syncSettingsToWatch(completion: ((WatchSettingsSyncResult) -> Void)? = nil) {
        guard WCSession.isSupported() else {
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: "Watch connectivity is not supported on this device."))
            }
            return
        }

        let message = WatchSyncPayload(settingsStore: settingsStore).message

        let session = WCSession.default

        guard session.activationState == .activated else {
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: "Watch connection is not active yet. Open the watch app once, then try again."))
            }
            return
        }

#if os(iOS)
        guard session.isPaired else {
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: "No paired Apple Watch was found."))
            }
            return
        }

        guard session.isWatchAppInstalled else {
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: "The Watch app is not installed. Install it on Apple Watch, then sync again."))
            }
            return
        }
#endif

        let contextError = sendApplicationContext(message)

        guard session.isReachable else {
            DispatchQueue.main.async {
                if let contextError {
                    completion?(.failed(Date(), reason: contextError.localizedDescription))
                } else {
                    completion?(.saved(Date(), reason: "Watch is not reachable. The update was saved and will apply when zShellWatch opens on Apple Watch."))
                }
            }
            return
        }

        session.sendMessage(message, replyHandler: { _ in
            DispatchQueue.main.async {
                completion?(.delivered(Date()))
            }
        }) { error in
            watchSessionLogger.error("Error sending settings to Apple Watch: \(error.localizedDescription, privacy: .public)")
            DispatchQueue.main.async {
                if contextError == nil {
                    completion?(.saved(Date(), reason: "Immediate sync failed, but the update was saved for Apple Watch. \(error.localizedDescription)"))
                } else {
                    completion?(.failed(Date(), reason: error.localizedDescription))
                }
            }
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        watchSessionLogger.info("Received file: \(String(describing: file.metadata), privacy: .public)")
        let key = file.metadata?["name"] as? String
        let path = FileManager.default.saveRecivedImage(srcURL: file.fileURL)
        if((key != nil) && (path != nil)){
            userdefaults?.setValue(path, forKey: key! );
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

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        watchSessionLogger.info("Received message with reply: \(String(describing: message), privacy: .public)")
        applySettings(message)
        replyHandler(["status": "applied"])
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

    private func sendApplicationContext(_ message: [String: Any]) -> Error? {
        guard WCSession.isSupported() else { return nil }

        do {
            try WCSession.default.updateApplicationContext(message)
            return nil
        } catch {
            watchSessionLogger.error("Error updating application context: \(error.localizedDescription, privacy: .public)")
            return error
        }
    }

    private func applySettings(_ message: [String: Any]) {
        if let payload = WatchSyncPayload(message: message) {
            settingsStore.applyPayload(payload)
            reloadWidgetTimelines()
            return
        }

        if let userName = message[qUserNameKey] as? String {
            userdefaults?.set(userName, forKey: qUserNameKey)
        }

        if let machineName = message[qMachineNameKey] as? String {
            userdefaults?.set(machineName, forKey: qMachineNameKey)
        }

        if let faceLineOrder = message[qFaceLineOrderKey] as? [String] {
            userdefaults?.set(faceLineOrder, forKey: qFaceLineOrderKey)
        }

        if let faceTheme = message[qFaceThemeKey] as? String {
            userdefaults?.set(faceTheme, forKey: qFaceThemeKey)
        }

        if let faceAnimation = message[qFaceAnimationKey] as? String {
            userdefaults?.set(faceAnimation, forKey: qFaceAnimationKey)
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
