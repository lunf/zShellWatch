//
//  SyncToastView.swift
//  TermiWatchWidget
//

import SwiftUI

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
