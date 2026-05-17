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
private let watchPreviewWidth: CGFloat = 200
private let watchPreviewMinimumHeight: CGFloat = 220
private let watchPreviewCornerRadius: CGFloat = 36
private let watchPreviewControlGap: CGFloat = 16
private let watchPreviewStatusPadding: CGFloat = 14
private let watchPreviewAnimationTopInset: CGFloat = 36
private let watchPreviewStatusContentInset: CGFloat = 38
private let watchPreviewContentInset: CGFloat = 8
private let themePickerTopInset: CGFloat = 8

private func watchPreviewHeight(lines: [TermiFaceLine], theme: TermiFaceTheme) -> CGFloat {
    let visibleLineWeight = max(lines.reduce(CGFloat(0)) { $0 + termiFaceLineHeightWeight($1, theme: theme) }, 1)
    let rowHeight = qRowHeight + 0.5
    let rowSpacing = CGFloat(max(lines.count - 1, 0)) * qFaceRowSpacing
    let contentHeight = qFacePaddingTop + qFacePaddingBottom + watchPreviewStatusContentInset + (visibleLineWeight * rowHeight) + rowSpacing
    return max(watchPreviewMinimumHeight, ceil(contentHeight + watchPreviewContentInset))
}

private func watchPreviewReservedHeight(lines: [TermiFaceLine]) -> CGFloat {
    TermiFaceTheme.allCases
        .map { watchPreviewHeight(lines: lines, theme: $0) }
        .max() ?? watchPreviewMinimumHeight
}

@main
struct TermiWatch: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var viewModel = QTermiViewModel()
    let userdefaults = qUserdefaults
    let session = WatchSessionManager.shared
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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GeometryReader { proxy in
                    let previewWidth = min(watchPreviewWidth, max(0, proxy.size.width - 32))
                    let previewHeight = watchPreviewHeight(lines: faceLines, theme: faceTheme)
                    let reservedPreviewHeight = watchPreviewReservedHeight(lines: faceLines)

                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: watchPreviewControlGap)

                            WatchFacePreview(viewModel: viewModel, faceLines: faceLines, theme: faceTheme, animation: faceAnimation)
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

        }
        //  If this reports an error, set true to false to support iOS 17 and earlier.
        //  If an error is reported here, it should be compatible with iOS17 or below, and true should be changed to false
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
        VStack(alignment: .leading, spacing: 4) {
            statusRow(title: LocalizedStringKey("Location"), value: locationStatus)
            statusRow(title: LocalizedStringKey("Health"), value: healthStatus)
            statusRow(title: LocalizedStringKey("Watch"), value: watchStatus)
            statusRow(title: LocalizedStringKey("Weather Source"), value: qWeatherSourceName)
            Divider().padding(.vertical, 4)
            statusRow(title: LocalizedStringKey("Sync"), value: syncStatusTitle)
            if !syncStatusDetail.isEmpty {
                Text(syncStatusDetail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            statusRow(title: LocalizedStringKey("Last Sync"), value: lastSyncText)
        }
        .frame(width: 300, alignment: .leading)
        .font(.system(size: 12))
    }

    var lastSyncText: String {
        guard let lastSyncDate else { return "Never" }
        return Self.syncDateFormatter.string(from: lastSyncDate)
    }

    private static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    func statusRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary).multilineTextAlignment(.trailing)
        }
    }

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
        userdefaults?.set(userName, forKey: qUserNameKey)
        userdefaults?.set(hostName, forKey: qMachineNameKey)
        saveSelectedFaceTheme(faceTheme, userDefaults: userdefaults)
        saveSelectedFaceAnimation(faceAnimation, userDefaults: userdefaults)
        userdefaults?.synchronize()
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
        saveSelectedFaceLines(lines, userDefaults: userdefaults)
        refreshWidgets()
    }

    func saveThemeSelection(_ theme: TermiFaceTheme) {
        faceTheme = theme
        saveSelectedFaceTheme(theme, userDefaults: userdefaults)
        refreshWidgets()
    }

    func saveAnimationSelection(_ animation: TermiFaceAnimation) {
        faceAnimation = animation
        saveSelectedFaceAnimation(animation, userDefaults: userdefaults)
        refreshWidgets()
    }

    func savePromptIdentity() {
        userdefaults?.set(userName, forKey: qUserNameKey)
        userdefaults?.set(hostName, forKey: qMachineNameKey)
        saveSelectedFaceTheme(faceTheme, userDefaults: userdefaults)
        saveSelectedFaceAnimation(faceAnimation, userDefaults: userdefaults)
        userdefaults?.synchronize()
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

struct ThemePickerStrip: View {
    @Binding var selectedTheme: TermiFaceTheme
    let onThemeChange: (TermiFaceTheme) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TermiFaceTheme.allCases) { theme in
                    Button {
                        selectedTheme = theme
                        onThemeChange(theme)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: theme.systemImage)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.accentColor)
                                .frame(width: 36, height: 36)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Text(LocalizedStringKey(theme.titleKey))
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .frame(width: 96, height: 78)
                        .background(selectedTheme == theme ? theme.accentColor.opacity(0.22) : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selectedTheme == theme ? theme.accentColor : Color.white.opacity(0.14), lineWidth: selectedTheme == theme ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel(LocalizedStringKey("Theme"))
    }
}

struct AnimationPickerDropdown: View {
    @Binding var selectedAnimation: TermiFaceAnimation
    let onAnimationChange: (TermiFaceAnimation) -> Void

    var body: some View {
        Menu {
            ForEach(TermiFaceAnimation.allCases) { animation in
                Button {
                    selectedAnimation = animation
                    onAnimationChange(animation)
                } label: {
                    Label(LocalizedStringKey(animation.titleKey), systemImage: animation.systemImage)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: selectedAnimation.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey("Animation"))
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(LocalizedStringKey(selectedAnimation.titleKey))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("Animation"))
    }
}

struct SyncToastView: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(iconColor.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private var iconName: String {
        switch title {
        case "Sent to Watch":
            return "checkmark.circle.fill"
        case "Saved for Watch", "Sending":
            return "arrow.triangle.2.circlepath.circle.fill"
        case "Sync Failed":
            return "exclamationmark.triangle.fill"
        default:
            return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch title {
        case "Sent to Watch":
            return .green
        case "Saved for Watch", "Sending":
            return .orange
        case "Sync Failed":
            return .red
        default:
            return .green
        }
    }
}

struct WatchFacePreview: View {
    let viewModel: QTermiViewModel
    let faceLines: [TermiFaceLine]
    let theme: TermiFaceTheme
    let animation: TermiFaceAnimation

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ContentView(viewModel: viewModel, faceLines: faceLines, theme: theme, animation: animation)
                .foregroundStyle(theme.textColor)
                .padding(.top, watchPreviewStatusContentInset)

            TermiCornerActivityView(theme: theme, animation: animation)
                .padding(.top, watchPreviewAnimationTopInset)
                .padding(.horizontal, watchPreviewStatusPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)

            TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                Text(Self.statusTimeFormatter.string(from: timeline.date))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textColor)
                    .monospacedDigit()
                    .padding(.top, watchPreviewStatusPadding)
                    .padding(.trailing, watchPreviewStatusPadding)
                    .allowsHitTesting(false)
            }
        }
        .background(.black)
    }

    private static let statusTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct FaceLineEditorView: View {
    @Binding var terminalUser: String
    @Binding var machineName: String
    @Binding var selectedLines: [TermiFaceLine]
    let onPromptIdentityChange: () -> Void
    let onLinesChange: ([TermiFaceLine]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    private var availableLines: [TermiFaceLine] {
        TermiFaceLine.allCases.filter { !selectedLines.contains($0) }
    }

    private var isEditing: Bool {
        editMode.isEditing
    }

    var body: some View {
        NavigationStack {
            List {
                Section(LocalizedStringKey("Terminal User")) {
                    TextField(LocalizedStringKey("Terminal User"), text: $terminalUser)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(onPromptIdentityChange)
                }

                Section(LocalizedStringKey("Machine Name")) {
                    TextField(LocalizedStringKey("Machine Name"), text: $machineName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(onPromptIdentityChange)
                }

                Section(LocalizedStringKey("Displayed Lines")) {
                    ForEach(selectedLines) { line in
                        Text(LocalizedStringKey(line.titleKey))
                    }
                    .onMove(perform: moveLines)
                    .onDelete(perform: removeLines)
                }

                Section(LocalizedStringKey("Available Lines")) {
                    ForEach(availableLines) { line in
                        Button {
                            addLine(line)
                        } label: {
                            HStack {
                                Text(LocalizedStringKey(line.titleKey))
                                Spacer()
                                Image(systemName: "plus.circle")
                            }
                        }
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.45 : 1)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Face Lines"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isEditing {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel(LocalizedStringKey("Done"))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            editMode = isEditing ? .inactive : .active
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle" : "arrow.up.arrow.down")
                    }
                    .accessibilityLabel(isEditing ? LocalizedStringKey("Done") : LocalizedStringKey("Edit"))
                }
            }
            .environment(\.editMode, $editMode)
        }
    }

    private func addLine(_ line: TermiFaceLine) {
        selectedLines.append(line)
        onLinesChange(selectedLines)
    }

    private func moveLines(from source: IndexSet, to destination: Int) {
        selectedLines.move(fromOffsets: source, toOffset: destination)
        onLinesChange(selectedLines)
    }

    private func removeLines(at offsets: IndexSet) {
        selectedLines.remove(atOffsets: offsets)
        onLinesChange(selectedLines)
    }
}

extension CLAuthorizationStatus {
    var statusText: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized"
        case .authorizedWhenInUse:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}

extension UIImage{
    func scaleTo( _ size: CGSize) -> UIImage? {
        if self.cgImage == nil { return nil }
        UIGraphicsBeginImageContext(size);
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return scaledImage;
    }
    func drawTo(newSize: CGSize, drawFrame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(newSize);
        draw(in: drawFrame)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return scaledImage;
    }

    func cropWithCropRect( _ crop: CGRect) -> UIImage? {
        let cropRect = CGRect(x: crop.origin.x * self.scale, y: crop.origin.y * self.scale, width: crop.size.width * self.scale, height: crop.size.height *  self.scale)
        if cropRect.size.width <= 0 || cropRect.size.height <= 0 {
           return nil
        }
        var image:UIImage?
        autoreleasepool{
           let imageRef: CGImage?  = self.cgImage!.cropping(to: cropRect)
           if let imageRef = imageRef {
               image = UIImage(cgImage: imageRef)
           }
        }
        return image
    }
}
