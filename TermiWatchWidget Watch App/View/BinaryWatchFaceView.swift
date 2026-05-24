//
//  BinaryWatchFaceView.swift
//  TermiWatchWidget
//

import SwiftUI

struct BinaryWatchFaceView: View {
    let date: Date
    let theme: TermiFaceTheme

    private let bitRows = [1, 2, 4, 8]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                binaryGroupTitle("HOUR")
                binaryGroupTitle("MIN")
                binaryGroupTitle("SEC")
            }

            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 6) {
                    ForEach(bitRows, id: \.self) { bit in
                        Text("\(bit)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.labelColor)
                            .frame(width: 14, height: 18, alignment: .trailing)
                    }
                }

                ForEach(Array(timeDigits.enumerated()), id: \.offset) { index, digit in
                    VStack(spacing: 6) {
                        ForEach(bitRows, id: \.self) { bit in
                            binaryDot(isOn: digit & bit != 0, index: index, bit: bit)
                        }
                    }
                    .frame(width: 18)

                    if index == 1 || index == 3 {
                        Color.clear.frame(width: 4)
                    }
                }
            }

            Text(binaryTimeText)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.textColor)
                .monospacedDigit()
        }
        .padding(.top, qFacePaddingTop + 8)
        .padding(.horizontal, qFacePaddingHorizontal)
        .padding(.bottom, qFacePaddingBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var timeDigits: [Int] {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0

        return [
            hour / 10,
            hour % 10,
            minute / 10,
            minute % 10,
            second / 10,
            second % 10
        ]
    }

    private var binaryTimeText: String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }

    private func binaryGroupTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(theme.labelColor)
            .frame(width: 42)
    }

    private func binaryDot(isOn: Bool, index: Int, bit: Int) -> some View {
        Circle()
            .fill(isOn ? binaryDotColor(index: index, bit: bit) : Color.white.opacity(0.12))
            .overlay {
                Circle()
                    .stroke(isOn ? Color.white.opacity(0.28) : Color.white.opacity(0.08), lineWidth: 1)
            }
            .frame(width: 14, height: 14)
            .shadow(color: isOn ? theme.accentColor.opacity(0.55) : .clear, radius: 4)
            .frame(width: 18, height: 18)
    }

    private func binaryDotColor(index: Int, bit: Int) -> Color {
        switch index / 2 {
        case 0:
            return theme.accentColor
        case 1:
            return Color(r: 0, g: 210, b: 255)
        default:
            return bit == 1 ? Color(r: 255, g: 214, b: 88) : Color(r: 78, g: 255, b: 154)
        }
    }
}
