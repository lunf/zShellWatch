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

    init(data: Data, decoder: JSONDecoder = JSONDecoder()) throws {
        self = try decoder.decode(Self.self, from: data)
    }

    func encodedData(encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(self)
    }
}
