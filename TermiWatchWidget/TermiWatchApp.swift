//
//  ViewController.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI
import WidgetKit
import CoreLocation
import WatchConnectivity
import OSLog

private let termiWatchLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "App")

@main
struct TermiWatch: App {
    @State private var viewModel = QTermiViewModel()
    private let session = WatchSessionManager.shared
    private let settingsStore = FaceSettingsStore()

    var body: some Scene {
        WindowGroup {
            MainScreen(viewModel: viewModel, session: session, settingsStore: settingsStore)
        }
    }
}

struct MainScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    let viewModel: QTermiViewModel
    let session: WatchSessionManager
    let settingsStore: FaceSettingsStore
    private var userdefaults: UserDefaults? { settingsStore.userDefaults }
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var syncStatusMessage = ""
    @State private var isShowingSyncToast = false
    @State private var locationStatus = "Checking"
    @State private var healthStatus = "Checking"
    @State private var watchStatus = "Checking"
    @State private var syncStatusTitle = "Not Synced"
    @State private var syncStatusDetail = "Tap export to send the current face."
    @State private var lastSyncDate: Date?
    @State private var isShowingStatusPanel = false
    @State private var isShowingFaceLineEditor = false
    @State private var faceLines = selectedFaceLines()
    @State private var faceTheme = selectedFaceTheme()
    @State private var faceAnimation = selectedFaceAnimation()
    @State private var didRunInitialRefresh = false
    @State var userName = terminalName()
    @State var hostName = machineName()

    init(viewModel: QTermiViewModel, session: WatchSessionManager, settingsStore: FaceSettingsStore) {
        self.viewModel = viewModel
        self.session = session
        self.settingsStore = settingsStore

        let configuration = settingsStore.loadConfiguration()
        _faceLines = State(initialValue: configuration.lines)
        _faceTheme = State(initialValue: configuration.theme)
        _faceAnimation = State(initialValue: configuration.animation)
        _userName = State(initialValue: configuration.terminalUser)
        _hostName = State(initialValue: configuration.machineName)
    }

    var body: some View {
        NavigationStack {
                GeometryReader { proxy in
                    let previewWidth = min(watchPreviewWidth, max(0, proxy.size.width - 32))
                    let previewHeight = watchPreviewHeight(lines: faceLines, theme: faceTheme)
                    let reservedPreviewHeight = watchPreviewReservedHeight(lines: faceLines)

                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: watchPreviewControlGap)

                            WatchFacePreview(viewModel: viewModel, configuration: currentConfiguration)
                                .frame(width: previewWidth, height: previewHeight, alignment: .top)
                                .clipShape(RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous)
                                        .stroke(faceTheme.accentColor, lineWidth: 1)
                                }
                                .frame(height: reservedPreviewHeight, alignment: .top)

                            ThemePickerStrip(selectedTheme: $faceTheme, onThemeChange: saveThemeSelection)
                                .padding(.horizontal, 16)
                                .padding(.top, watchPreviewControlGap + themePickerTopInset)

                            AnimationPickerDropdown(selectedAnimation: $faceAnimation, onAnimationChange: saveAnimationSelection)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .background(.black)
                    .scrollContentBackground(.hidden)
                }
                .background(.black)
                .toolbarBackground(.gray, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            updateStatus()
                            isShowingStatusPanel = true
                        } label: {
                            Image(systemName: "link.circle")
                        }
                        .accessibilityLabel(LocalizedStringKey("Connection Status"))
                        .popover(isPresented: $isShowingStatusPanel) {
                            statusPanel
                                .padding(16)
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingFaceLineEditor = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel(LocalizedStringKey("Configure Lines"))
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: syncWatchFace) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(LocalizedStringKey("Sync Watch Face"))
                    }
                }
                .overlay(alignment: .top) {
                    if isShowingSyncToast {
                        SyncToastView(title: syncStatusTitle, message: syncStatusMessage)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            }
            .alert(LocalizedStringKey("Error"), isPresented: $isShowingError) {
                Button(LocalizedStringKey("OK"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $isShowingFaceLineEditor) {
                FaceLineEditorView(
                    terminalUser: $userName,
                    machineName: $hostName,
                    selectedLines: $faceLines,
                    onPromptIdentityChange: savePromptIdentity,
                    onLinesChange: saveFaceLineSelection
                )
                .onDisappear {
                    refreshWidgets()
                }
            }
        // If this reports an error, set true to false to support iOS 17 and earlier.
#if true
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .active:
                termiWatchLogger.debug("Active")
                refreshAfterFirstFrame()

//                motionViewModel.startMotionUpdates()

            case .inactive:
                termiWatchLogger.debug("Inactive")
            case .background:
                termiWatchLogger.debug("Background")
            @unknown default: break
            }
        }
#else
        .onChange(of: scenePhase) { phase in

            if(phase == .active){
                viewModel.updateModel()
                updateStatus()
            }
        }
#endif
    }

    var statusPanel: some View {
        StatusPanelView(
            locationStatus: locationStatus,
            healthStatus: healthStatus,
            watchStatus: watchStatus,
            weatherSourceName: qWeatherSourceName,
            syncStatusTitle: syncStatusTitle,
            syncStatusDetail: syncStatusDetail,
            lastSyncText: lastSyncText
        )
    }

    var lastSyncText: String {
        guard let lastSyncDate else { return "Never" }
        return Self.syncDateFormatter.string(from: lastSyncDate)
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

    private static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    func syncWatchFace() {
        syncStatusTitle = "Sending"
        syncStatusDetail = "Sending current face settings to Apple Watch..."
        showSyncToast()
        refreshWidgets(syncToWatch: false)
        session.syncSettingsToWatch { result in
            applySyncResult(result)
            showSyncToast()
        }
    }

    func refreshWidgets(syncToWatch: Bool = true) {
        settingsStore.saveConfiguration(currentConfiguration)
        if syncToWatch {
            session.syncSettingsToWatch()
        }

        viewModel.updateModel()
        WidgetCenter.shared.reloadTimelines(ofKind: "HealthWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "CircularWidget")
        updateStatus()
    }

    func refreshAfterFirstFrame() {
        guard didRunInitialRefresh else {
            didRunInitialRefresh = true
            Task { @MainActor in
                await Task.yield()
                viewModel.updateModel()
                updateStatus()
            }
            return
        }

        viewModel.updateModel()
        updateStatus()
    }

    func saveFaceLineSelection(_ lines: [TermiFaceLine]) {
        faceLines = lines
        refreshWidgets()
    }

    func saveThemeSelection(_ theme: TermiFaceTheme) {
        faceTheme = theme
        refreshWidgets()
    }

    func saveAnimationSelection(_ animation: TermiFaceAnimation) {
        faceAnimation = animation
        refreshWidgets()
    }

    func savePromptIdentity() {
        refreshWidgets()
    }

    func updateStatus() {
        let locationAuthorization = CLLocationManager().authorizationStatus
        locationStatus = locationAuthorization.statusText

        healthStatus = qUseHealthKit ? "Available" : "Disabled"

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

    func applySyncResult(_ result: WatchSettingsSyncResult) {
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

    func showSyncToast() {
        syncStatusMessage = syncStatusDetail
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingSyncToast = true
        }

        let currentMessage = syncStatusMessage
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard currentMessage == syncStatusMessage else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                isShowingSyncToast = false
            }
        }
    }

    func showError(_ message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            isShowingError = true
        }
    }

}
