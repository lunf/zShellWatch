//
//  FaceSettingsStore.swift
//  TermiWatchWidget
//

import Foundation

struct FaceSettingsStore {
    var userDefaults: UserDefaults? = qUserdefaults

    func loadConfiguration() -> WatchFaceConfiguration {
        WatchFaceConfiguration(
            terminalUser: userDefaults?.string(forKey: qUserNameKey) ?? "void",
            machineName: {
                let value = userDefaults?.string(forKey: qMachineNameKey) ?? "local"
                return value.isEmpty ? "local" : value
            }(),
            lines: selectedFaceLines(userDefaults: userDefaults),
            theme: selectedFaceTheme(userDefaults: userDefaults),
            animation: selectedFaceAnimation(userDefaults: userDefaults)
        )
    }

    func saveConfiguration(_ configuration: WatchFaceConfiguration) {
        userDefaults?.set(configuration.terminalUser, forKey: qUserNameKey)
        userDefaults?.set(configuration.machineName, forKey: qMachineNameKey)
        userDefaults?.set(configuration.lines.map(\.rawValue), forKey: qFaceLineOrderKey)
        userDefaults?.set(configuration.theme.rawValue, forKey: qFaceThemeKey)
        userDefaults?.set(configuration.animation.rawValue, forKey: qFaceAnimationKey)

        userDefaults?.synchronize()
    }

    func applyPayload(_ payload: WatchSyncPayload) {
        switch payload.command {
        case .syncSettings:
            if let configuration = payload.configuration {
                saveConfiguration(configuration)
            }
        }
    }
}
