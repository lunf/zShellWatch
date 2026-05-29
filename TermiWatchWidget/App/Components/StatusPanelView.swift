//
//  StatusPanelView.swift
//  TermiWatchWidget
//

import SwiftUI

struct StatusPanelView: View {
    let locationStatus: String
    let healthStatus: String
    let watchStatus: String
    let storageStatus: String
    let storageDetail: String
    let weatherSourceName: String
    let syncStatusTitle: String
    let syncStatusDetail: String
    let lastSyncText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            statusRow(title: LocalizedStringKey("Location"), value: locationStatus)
            statusRow(title: LocalizedStringKey("Health"), value: healthStatus)
            statusRow(title: LocalizedStringKey("Watch"), value: watchStatus)
            statusRow(title: LocalizedStringKey("Storage"), value: storageStatus)
            if !storageDetail.isEmpty {
                Text(storageDetail)
                    .foregroundStyle(storageStatus == "App Group" ? Color.secondary : Color.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            statusRow(title: LocalizedStringKey("Weather Source"), value: weatherSourceName)
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

    private func statusRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.primary).multilineTextAlignment(.trailing)
        }
    }
}
