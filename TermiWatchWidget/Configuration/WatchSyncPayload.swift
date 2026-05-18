//
//  WatchSyncPayload.swift
//  TermiWatchWidget
//

import Foundation

enum WatchSyncCommand: String, Codable, Equatable {
    case syncSettings
}

struct WatchSyncPayload: Codable, Equatable {
    var command: WatchSyncCommand
    var configuration: WatchFaceConfiguration?

    init(command: WatchSyncCommand, configuration: WatchFaceConfiguration? = nil) {
        self.command = command
        self.configuration = configuration
    }

    init(settingsStore: FaceSettingsStore = FaceSettingsStore()) {
        self.init(command: .syncSettings, configuration: settingsStore.loadConfiguration())
    }

    init?(message: [String: Any]) {
        guard let rawCommand = message[qWatchSessionSyncCommandKey] as? String,
              let command = WatchSyncCommand(rawValue: rawCommand) else {
            return nil
        }

        self.command = command

        if command == .syncSettings {
            let lines = availableFaceLines(
                from: (message[qFaceLineOrderKey] as? [String])?.compactMap(TermiFaceLine.init(rawValue:)) ?? selectedFaceLines()
            )
            let theme = (message[qFaceThemeKey] as? String).flatMap(TermiFaceTheme.init(rawValue:)) ?? selectedFaceTheme()
            let animation = (message[qFaceAnimationKey] as? String).flatMap(TermiFaceAnimation.init(rawValue:)) ?? selectedFaceAnimation()
            configuration = WatchFaceConfiguration(
                terminalUser: message[qUserNameKey] as? String ?? terminalName(),
                machineName: message[qMachineNameKey] as? String ?? machineName(),
                lines: lines,
                theme: theme,
                animation: animation
            )
        }
    }

    var message: [String: Any] {
        var message: [String: Any] = [qWatchSessionSyncCommandKey: command.rawValue]

        guard let configuration else {
            return message
        }

        message[qUserNameKey] = configuration.terminalUser
        message[qMachineNameKey] = configuration.machineName
        message[qFaceLineOrderKey] = configuration.lines.map(\.rawValue)
        message[qFaceThemeKey] = configuration.theme.rawValue
        message[qFaceAnimationKey] = configuration.animation.rawValue

        return message
    }
}
