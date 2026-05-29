//
//  ViewController.swift
//  TermiWatchWidget
//
//  Created by Qianlishun on 2023/10/10.
//

import SwiftUI

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
    @State private var screenModel: MainScreenViewModel

    init(viewModel: QTermiViewModel, session: WatchSessionManager, settingsStore: FaceSettingsStore) {
        self.viewModel = viewModel
        _screenModel = State(initialValue: MainScreenViewModel(
            faceDataViewModel: viewModel,
            session: session,
            settingsStore: settingsStore
        ))
    }

    var body: some View {
        @Bindable var screenModel = screenModel

        NavigationStack {
                GeometryReader { proxy in
                    let previewWidth = min(watchPreviewWidth, max(0, proxy.size.width - 32))
                    let previewHeight = watchPreviewHeight(lines: screenModel.faceLines, theme: screenModel.faceTheme)
                    let reservedPreviewHeight = watchPreviewReservedHeight(lines: screenModel.faceLines)

                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: watchPreviewControlGap)

                            WatchFacePreview(viewModel: viewModel, configuration: screenModel.currentConfiguration)
                                .frame(width: previewWidth, height: previewHeight, alignment: .top)
                                .clipShape(RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous)
                                        .stroke(screenModel.faceTheme.accentColor, lineWidth: 1)
                                }
                                .frame(height: reservedPreviewHeight, alignment: .top)

                            ThemePickerStrip(selectedTheme: $screenModel.faceTheme, onThemeChange: screenModel.saveThemeSelection)
                                .padding(.horizontal, 16)
                                .padding(.top, watchPreviewControlGap + themePickerTopInset)

                            AnimationPickerDropdown(selectedAnimation: $screenModel.faceAnimation, onAnimationChange: screenModel.saveAnimationSelection)
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
                            screenModel.updateStatus()
                            screenModel.isShowingStatusPanel = true
                        } label: {
                            Image(systemName: "link.circle")
                        }
                        .accessibilityLabel(LocalizedStringKey("Connection Status"))
                        .popover(isPresented: $screenModel.isShowingStatusPanel) {
                            StatusPanelView(
                                locationStatus: screenModel.locationStatus,
                                healthStatus: screenModel.healthStatus,
                                watchStatus: screenModel.watchStatus,
                                storageStatus: screenModel.storageStatus,
                                storageDetail: screenModel.storageDetail,
                                weatherSourceName: qWeatherSourceName,
                                syncStatusTitle: screenModel.syncStatusTitle,
                                syncStatusDetail: screenModel.syncStatusDetail,
                                lastSyncText: screenModel.lastSyncText
                            )
                                .padding(16)
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            screenModel.isShowingFaceLineEditor = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel(LocalizedStringKey("Configure Lines"))
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: screenModel.syncWatchFace) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(LocalizedStringKey("Sync Watch Face"))
                    }
                }
                .overlay(alignment: .top) {
                    if screenModel.isShowingSyncToast {
                        SyncToastView(title: screenModel.syncStatusTitle, message: screenModel.syncStatusMessage)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            }
            .alert(LocalizedStringKey("Error"), isPresented: $screenModel.isShowingError) {
                Button(LocalizedStringKey("OK"), role: .cancel) {}
            } message: {
                Text(screenModel.errorMessage)
            }
            .sheet(isPresented: $screenModel.isShowingFaceLineEditor) {
                FaceLineEditorView(
                    terminalUser: $screenModel.userName,
                    machineName: $screenModel.hostName,
                    selectedLines: $screenModel.faceLines,
                    onPromptIdentityChange: screenModel.savePromptIdentity,
                    onLinesChange: screenModel.saveFaceLineSelection
                )
                .onDisappear {
                    screenModel.refreshWidgets()
                }
            }
        .onChange(of: scenePhase, initial: true) {
            screenModel.handleScenePhase(scenePhase)
        }
    }
}
