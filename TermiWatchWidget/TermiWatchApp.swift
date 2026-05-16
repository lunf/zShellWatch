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
private let watchPreviewHeight: CGFloat = 220
private let watchPreviewCornerRadius: CGFloat = 36
private let watchPreviewControlGap: CGFloat = 16
private let watchPreviewStatusPadding: CGFloat = 14
private let watchPreviewStatusContentInset: CGFloat = 24

@main
struct TermiWatch: App {
    @Environment(\.scenePhase) private var scenePhase
    @State var viewModel = QTermiViewModel()
    let userdefaults = qUserdefaults
    let session = WatchSessionManager.shared
    @State private var errorMessage = ""
    @State private var isShowingError = false
    @State private var syncStatusMessage = ""
    @State private var isShowingSyncStatus = false
    @State private var locationStatus = "Checking"
    @State private var healthStatus = "Checking"
    @State private var watchStatus = "Checking"
    @State private var isShowingStatusPanel = false
    @State private var isShowingFaceLineEditor = false
    @State private var faceLines = selectedFaceLines()
    @State private var didRunInitialRefresh = false
    @State var userName = terminalName()
    @State var hostName = machineName()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GeometryReader { proxy in
                    let previewWidth = min(watchPreviewWidth, max(0, proxy.size.width - 32))

                    ScrollView {
                        VStack(spacing: watchPreviewControlGap) {
                            Color.clear.frame(height: watchPreviewControlGap)

                            WatchFacePreview(viewModel: viewModel, faceLines: faceLines)
                                .frame(width: previewWidth, height: watchPreviewHeight, alignment: .top)
                                .clipShape(RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: watchPreviewCornerRadius, style: .continuous)
                                        .stroke(.green, lineWidth: 1)
                                }
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
            }
            .alert(LocalizedStringKey("Error"), isPresented: $isShowingError) {
                Button(LocalizedStringKey("OK"), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert(LocalizedStringKey("Sync Watch Face"), isPresented: $isShowingSyncStatus) {
                Button(LocalizedStringKey("OK"), role: .cancel) {}
            } message: {
                Text(syncStatusMessage)
            }
            .sheet(isPresented: $isShowingFaceLineEditor) {
                FaceLineEditorView(
                    terminalUser: $userName,
                    machineName: $hostName,
                    selectedLines: $faceLines,
                    onPromptIdentityChange: savePromptIdentity,
                    onLinesChange: saveFaceLineSelection
                )
                .onDisappear(perform: refreshWidgets)
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
        }
        .frame(width: 300, alignment: .leading)
        .font(.system(size: 12))
    }

    func statusRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary).multilineTextAlignment(.trailing)
        }
    }

    func syncWatchFace() {
        refreshWidgets()
        syncStatusMessage = syncStatusText()
        isShowingSyncStatus = true
    }

    func refreshWidgets() {
        userdefaults?.set(userName, forKey: qUserNameKey)
        userdefaults?.set(hostName, forKey: qMachineNameKey)
        userdefaults?.synchronize()
        session.syncSettingsToWatch()

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

    func savePromptIdentity() {
        userdefaults?.set(userName, forKey: qUserNameKey)
        userdefaults?.set(hostName, forKey: qMachineNameKey)
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

    func syncStatusText() -> String {
        guard WCSession.isSupported() else {
            return "Watch connectivity is not supported on this device."
        }

        let watchSession = WCSession.default

        guard watchSession.activationState == .activated else {
            return "Watch connection is not active yet. Open the watch app once, then try again."
        }

        guard watchSession.isPaired else {
            return "No paired Apple Watch was found."
        }

        guard watchSession.isWatchAppInstalled else {
            return "The Watch app is not installed. Install it on Apple Watch, then sync again."
        }

        if watchSession.isReachable {
            return "Sent to Apple Watch. Keep the watch app open to see the update immediately."
        }

        return "Saved for Apple Watch. Open zShellWatch on the watch to apply the update."
    }

    func showError(_ message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            isShowingError = true
        }
    }

}

struct WatchFacePreview: View {
    let viewModel: QTermiViewModel
    let faceLines: [TermiFaceLine]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ContentView(viewModel: viewModel, faceLines: faceLines)
                .foregroundStyle(.white)
                .padding(.top, watchPreviewStatusContentInset)

            TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                Text(Self.statusTimeFormatter.string(from: timeline.date))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
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
