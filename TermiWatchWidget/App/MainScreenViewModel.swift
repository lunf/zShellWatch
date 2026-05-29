//
//  MainScreenViewModel.swift
//  TermiWatchWidget
//

import CoreLocation
import OSLog
import Observation
import SwiftUI
import WatchConnectivity
import WidgetKit

private let mainScreenLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "MainScreen")

@MainActor
@Observable
final class MainScreenViewModel {
    @ObservationIgnored private let faceDataViewModel: QTermiViewModel
    @ObservationIgnored private let session: WatchSessionManager
    @ObservationIgnored private let settingsStore: FaceSettingsStore

    var errorMessage = ""
    var isShowingError = false
    var syncStatusMessage = ""
    var isShowingSyncToast = false
    var locationStatus = "Checking"
    var healthStatus = "Checking"
    var watchStatus = "Checking"
    var storageStatus = qAppGroupStorageStatus.statusText
    var storageDetail = qAppGroupStorageStatus.detailText
    var syncStatusTitle = "Not Synced"
    var syncStatusDetail = "Tap export to send the current face."
    var lastSyncDate: Date?
    var isShowingStatusPanel = false
    var isShowingFaceLineEditor = false
    var faceLines: [TermiFaceLine]
    var faceTheme: TermiFaceTheme
    var faceAnimation: TermiFaceAnimation
    var userName: String
    var hostName: String

    private var didRunInitialRefresh = false

    init(
        faceDataViewModel: QTermiViewModel,
        session: WatchSessionManager,
        settingsStore: FaceSettingsStore
    ) {
        self.faceDataViewModel = faceDataViewModel
        self.session = session
        self.settingsStore = settingsStore

        let configuration = settingsStore.loadConfiguration()
        self.faceLines = configuration.lines
        self.faceTheme = configuration.theme
        self.faceAnimation = configuration.animation
        self.userName = configuration.terminalUser
        self.hostName = configuration.machineName
    }

    var currentConfiguration: WatchFaceConfiguration {
        WatchFaceConfiguration(
            terminalUser: userName,
            machineName: hostName,
            lines: faceLines,
            theme: faceTheme,
            animation: faceAnimation
        )
    }

    var lastSyncText: String {
        guard let lastSyncDate else { return "Never" }
        return Self.syncDateFormatter.string(from: lastSyncDate)
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            mainScreenLogger.debug("Active")
            refreshAfterFirstFrame()
        case .inactive:
            mainScreenLogger.debug("Inactive")
        case .background:
            mainScreenLogger.debug("Background")
        @unknown default:
            break
        }
    }

    func syncWatchFace() {
        syncStatusTitle = "Sending"
        syncStatusDetail = "Sending current face settings to Apple Watch..."
        showSyncToast()
        refreshWidgets(syncToWatch: false)
        session.syncSettingsToWatch { [weak self] result in
            self?.applySyncResult(result)
            self?.showSyncToast()
        }
    }

    func refreshWidgets(syncToWatch: Bool = true) {
        settingsStore.saveConfiguration(currentConfiguration)
        if syncToWatch {
            session.syncSettingsToWatch()
        }

        faceDataViewModel.updateModel()
        WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "CircularWidget")
        updateStatus()
    }

    func saveFaceSettings(syncToWatch: Bool = true) {
        settingsStore.saveConfiguration(currentConfiguration)
        if syncToWatch {
            session.syncSettingsToWatch()
        }

        updateStatus()
    }

    func saveFaceLineSelection(_ lines: [TermiFaceLine]) {
        faceLines = lines
        refreshWidgets()
    }

    func saveThemeSelection(_ theme: TermiFaceTheme) {
        faceTheme = theme
        saveFaceSettings()
    }

    func saveAnimationSelection(_ animation: TermiFaceAnimation) {
        faceAnimation = animation
        saveFaceSettings()
    }

    func savePromptIdentity() {
        refreshWidgets()
    }

    func updateStatus() {
        let locationAuthorization = CLLocationManager().authorizationStatus
        locationStatus = locationAuthorization.statusText

        healthStatus = qUseHealthKit ? "Available" : "Disabled"
        storageStatus = qAppGroupStorageStatus.statusText
        storageDetail = qAppGroupStorageStatus.detailText

        guard WCSession.isSupported() else {
            watchStatus = "Unsupported"
            return
        }

        switch WCSession.default.activationState {
        case .activated:
            watchStatus = WCSession.default.isReachable ? "Reachable" : "Paired"
        case .inactive:
            watchStatus = "Inactive"
        case .notActivated:
            watchStatus = "Not Activated"
        @unknown default:
            watchStatus = "Unknown"
        }
    }

    func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }

    private func refreshAfterFirstFrame() {
        guard didRunInitialRefresh else {
            didRunInitialRefresh = true
            Task { @MainActor in
                await Task.yield()
                faceDataViewModel.updateModel()
                updateStatus()
            }
            return
        }

        faceDataViewModel.updateModel()
        updateStatus()
    }

    private func applySyncResult(_ result: WatchSettingsSyncResult) {
        switch result {
        case .delivered(let date):
            syncStatusTitle = "Sent to Watch"
            syncStatusDetail = "Apple Watch acknowledged the update. Keep zShellWatch open on the watch to see it immediately."
            lastSyncDate = date
        case .saved(let date, let reason):
            syncStatusTitle = "Saved for Watch"
            syncStatusDetail = reason
            lastSyncDate = date
        case .failed(let date, let reason):
            syncStatusTitle = "Sync Failed"
            syncStatusDetail = reason
            lastSyncDate = date
        }
    }

    private func showSyncToast() {
        syncStatusMessage = syncStatusDetail
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingSyncToast = true
        }

        let currentMessage = syncStatusMessage
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard currentMessage == syncStatusMessage else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                isShowingSyncToast = false
            }
        }
    }

    private static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}
