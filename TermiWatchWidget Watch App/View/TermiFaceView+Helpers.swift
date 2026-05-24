//
//  TermiFaceView+Helpers.swift
//  TermiWatchWidget
//

import SwiftUI
#if os(watchOS)
import WatchKit
#elseif os(iOS)
import UIKit
#endif

extension TermiFaceView {
    func lineColor(for line: TermiFaceLine, fallback: Color) -> Color {
        guard theme == .git else {
            return fallback
        }

        return gitLineColor(for: line)
    }

    var gitBranchFont: Font {
        .system(size: theme.fontSize, weight: .bold, design: .monospaced)
    }

    var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    @ViewBuilder
    func gitNumberText(_ text: String, line: TermiFaceLine, fontSize: CGFloat? = nil, color: Color) -> some View {
        if shouldShowGitBadge(text, line: line) {
            HStack(spacing: 2) {
                Image(systemName: gitBadgeIconName(for: line, text: text))
                    .font(.system(size: 7, weight: .bold))
                Text(text)
                    .font(Font.custom(theme.fontName, size: fontSize ?? max(theme.fontSize - 1, 9)))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Capsule().fill(.red))
            .fixedSize(horizontal: true, vertical: true)
        } else if let fontSize {
            MyText(text, fontSize: fontSize, color: color)
        } else {
            MyText(text, color: color)
        }
    }

    func shouldShowGitBadge(_ text: String, line: TermiFaceLine) -> Bool {
        theme == .git && gitColorIndex(for: line) == 1 && text.contains { $0.isNumber }
    }

    func gitBadgeIconName(for line: TermiFaceLine, text: String) -> String {
        let fiveMinuteBucket = Int(Date().timeIntervalSinceReferenceDate / 300)
        let seedText = "\(line.rawValue)|\(text)"
        let seed = seedText.unicodeScalars.reduce(fiveMinuteBucket) { result, scalar in
            (result &* 31) &+ Int(scalar.value)
        }

        return abs(seed) % 2 == 0 ? "plus.circle.fill" : "minus.circle.fill"
    }

    func iconLineColor(for line: TermiFaceLine, fallback: Color) -> Color {
        guard theme == .git else {
            return fallback
        }

        return gitLineColor(for: line)
    }

    func gitLineColor(for line: TermiFaceLine) -> Color {
        gitColor(for: gitColorIndex(for: line))
    }

    func gitColor(for index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .red
        default: return .white
        }
    }

    func gitColorIndex(for line: TermiFaceLine) -> Int {
        let fiveMinuteBucket = Int(Date().timeIntervalSinceReferenceDate / 300)
        let seed = line.rawValue.unicodeScalars.reduce(fiveMinuteBucket) { result, scalar in
            (result &* 31) &+ Int(scalar.value)
        }

        return abs(seed) % 3
    }

    func timeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func batteryText() -> String {
#if os(watchOS)
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        let batteryLevel = device.batteryLevel
#elseif os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
#else
        let batteryLevel: Float = -1
#endif
        guard batteryLevel >= 0 else {
            return "--%"
        }

        return "\(Int(batteryLevel * 100))%"
    }
}
