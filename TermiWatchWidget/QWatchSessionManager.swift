//
//  QWatchSessionManager.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2025/2/24.
//

import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchSessionManager()
    let userdefaults = UserDefaults.init(suiteName: qGroupBundleID)

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
        
    func sendImage(images: [String: URL]){
        if WCSession.default.isReachable {
            for (iKey,iValue) in images{
                let name = ["name" : iKey]
                WCSession.default.transferFile(iValue, metadata: name)
            }
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Received File : \(String(describing: file.metadata))")
        let key = file.metadata?["name"] as? String
        let path = FileManager.default.saveRecivedImage(srcURL: file.fileURL)
        if((key != nil) && (path != nil)){
            userdefaults?.setValue(path, forKey: key! );
            
            if(path?.contains("_") == true){
                let custom = path?.components(separatedBy: "_").first
                userdefaults?.setValue(custom, forKey: qCustomImageKey)
            }
            userdefaults?.synchronize()
        }
    }
    
    func sendData(data: Data){
        if WCSession.default.isReachable {
         
            WCSession.default.sendMessageData(data, replyHandler: nil) { error in
                print("Error sending messageData to Apple Watch: \(error.localizedDescription)")
            }
            
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("Received messageData : \(messageData.count)")

      
    }
    
    // 发送消息
    func sendMessage(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to Apple Watch: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable.")
        }
    }
    
    //  接收到的消息
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message : \(message)")
    }
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("Session did deactivate.")
    }
#endif

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed with error: \(error.localizedDescription)")
        } else {
            print("Session activated with state: \(activationState)")
        }
    }
}
