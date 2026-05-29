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

        let payload: WatchSyncPayload
        let payloadData: Data

        do {
            payload = WatchSyncPayload(settingsStore: settingsStore)
            payloadData = try payload.encodedData()
        } catch {
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: "Could not encode watch face settings. \(error.localizedDescription)"))
            }
            return
        }

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

        do {
            try updateApplicationContext(with: payloadData)
            DispatchQueue.main.async {
                if session.isReachable {
                    completion?(.saved(Date(), reason: "Watch face settings were queued for Apple Watch. Keep zShellWatch open on the watch to apply them immediately."))
                } else {
                    completion?(.saved(Date(), reason: "Watch is not reachable. The update was saved and will apply when zShellWatch opens on Apple Watch."))
                }
            }
        } catch {
            watchSessionLogger.error("Error updating watch application context: \(error.localizedDescription, privacy: .public)")
            DispatchQueue.main.async {
                completion?(.failed(Date(), reason: error.localizedDescription))
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
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let payloadData = applicationContext[qWatchSessionPayloadDataKey] as? Data else {
            watchSessionLogger.warning("Received application context without watch sync payload.")
            return
        }

        watchSessionLogger.info("Received watch sync payload: \(payloadData.count, privacy: .public) bytes")
        applySettings(payloadData)
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

    private func updateApplicationContext(with payloadData: Data) throws {
        guard WCSession.isSupported() else { return }
        try WCSession.default.updateApplicationContext([qWatchSessionPayloadDataKey: payloadData])
    }

    private func applySettings(_ payloadData: Data) {
        do {
            let payload = try WatchSyncPayload(data: payloadData)
            settingsStore.applyPayload(payload)
        } catch {
            watchSessionLogger.error("Could not decode watch sync payload: \(error.localizedDescription, privacy: .public)")
            return
        }

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
