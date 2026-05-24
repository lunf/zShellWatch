//
//  TermiCornerActivityView.swift
//  TermiWatchWidget
//

import SwiftUI

struct TermiCornerActivityView: View {
    private let activityUnitCount = 60
    let theme: TermiFaceTheme
    let animation: TermiFaceAnimation

    @ViewBuilder
    var body: some View {
        if animation == .none {
            EmptyView()
        } else {
            TimelineView(.periodic(from: Date(), by: 1)) { timeline in
                activityContent(date: timeline.date)
            }
        }
    }

    @ViewBuilder
    private func activityContent(date: Date) -> some View {
        switch animation {
        case .dotLine:
            dotLine(date: date)
                .activityCapsule(theme: theme)
        case .matrixText:
            matrixText(date: date)
                .activityCapsule(theme: theme)
        case .pacman:
            pacmanLine(date: date)
                .activityCapsule(theme: theme)
        case .terminalCursor:
            terminalCursor(date: date)
                .activityCapsule(theme: theme)
        case .commandLoader:
            commandLoader(date: date)
                .activityCapsule(theme: theme)
        case .signalSweep:
            signalSweep(date: date)
                .activityCapsule(theme: theme)
        case .none:
            EmptyView()
        }
    }

    private func dotLine(date: Date) -> some View {
        let activeDot = secondIndex(date)

        return GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let centerY = proxy.size.height / 2

            ZStack(alignment: .topLeading) {
                ForEach(0..<activityUnitCount, id: \.self) { index in
                    let isActive = index == activeDot
                    let dotSize: CGFloat = isActive ? 3.6 : 2.0

                    Circle()
                        .fill(dotStyle)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: activityUnitX(index, width: width), y: centerY + (isActive ? -1.0 : 0.7))
                        .opacity(isActive ? 1 : 0.35)
                        .animation(.easeInOut(duration: 0.2), value: activeDot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 7)
    }

    private func matrixText(date: Date) -> some View {
        let second = Int(date.timeIntervalSinceReferenceDate)
        let characters = matrixCharacters(second: second)

        return HStack(spacing: 0) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 4, weight: index == secondIndex(date) ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(matrixColor(for: index, second: second))
                    .frame(width: 1.6)

                if index < activityUnitCount - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func pacmanLine(date: Date) -> some View {
        let activeDot = secondIndex(date)

        return HStack(spacing: 0) {
            ForEach(0..<activityUnitCount, id: \.self) { index in
                if index == activeDot {
                    PacmanShape(mouthOpen: activeDot % 2 == 0)
                        .fill(.yellow)
                        .frame(width: 5.4, height: 5.4)
                        .transition(.scale)
                } else {
                    Circle()
                        .fill(.white)
                        .frame(width: 1.6, height: 1.6)
                        .opacity(index < activeDot ? 0.2 : 0.75)
                }

                if index < activityUnitCount - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: activeDot)
    }

    private func terminalCursor(date: Date) -> some View {
        let activeDot = secondIndex(date)
        let isCursorVisible = Int(date.timeIntervalSinceReferenceDate) % 2 == 0

        return GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let centerY = proxy.size.height / 2

            ZStack(alignment: .topLeading) {
                ForEach(0..<activityUnitCount, id: \.self) { index in
                    Circle()
                        .fill(dotStyle)
                        .frame(width: 1.5, height: 1.5)
                        .position(x: activityUnitX(index, width: width), y: centerY + 1.8)
                        .opacity(0.22)
                }

                RoundedRectangle(cornerRadius: 1.2, style: .continuous)
                    .fill(theme.accentColor)
                    .frame(width: 4.2, height: 7)
                    .position(x: activityUnitX(activeDot, width: width), y: centerY)
                    .opacity(isCursorVisible ? 1 : 0.35)
                    .shadow(color: theme.accentColor.opacity(0.7), radius: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 9)
        .animation(.easeInOut(duration: 0.18), value: activeDot)
    }

    private func commandLoader(date: Date) -> some View {
        let activeDot = secondIndex(date)
        let frame = Int(date.timeIntervalSinceReferenceDate) % commandLoaderFrames.count
        let loader = commandLoaderFrames[frame]

        return GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let centerY = proxy.size.height / 2

            ZStack(alignment: .topLeading) {
                ForEach(0..<activityUnitCount, id: \.self) { index in
                    Rectangle()
                        .fill(theme.accentColor.opacity(index == activeDot ? 0.65 : 0.22))
                        .frame(width: 1.2, height: index == activeDot ? 5 : 2)
                        .position(x: activityUnitX(index, width: width), y: centerY + 1.6)
                }

                Text(loader)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 8, height: 8)
                    .position(x: activityUnitX(activeDot, width: width), y: centerY - 1.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 10)
        .animation(.easeInOut(duration: 0.18), value: activeDot)
    }

    private func signalSweep(date: Date) -> some View {
        let activeDot = secondIndex(date)

        return GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let centerY = proxy.size.height / 2

            ZStack(alignment: .topLeading) {
                ForEach(0..<activityUnitCount, id: \.self) { index in
                    let distance = cyclicDistance(from: index, to: activeDot)
                    let isInWave = distance <= 7
                    let dotSize = isInWave ? CGFloat(4.4 - (Double(distance) * 0.32)) : 1.6
                    let opacity = isInWave ? Double(1.0 - (Double(distance) * 0.09)) : 0.22

                    Circle()
                        .fill(signalSweepColor(distance: distance))
                        .frame(width: max(dotSize, 1.6), height: max(dotSize, 1.6))
                        .position(x: activityUnitX(index, width: width), y: centerY)
                        .opacity(opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 9)
        .animation(.easeInOut(duration: 0.22), value: activeDot)
    }

    private func secondIndex(_ date: Date) -> Int {
        Int(date.timeIntervalSinceReferenceDate) % activityUnitCount
    }

    private func activityUnitX(_ index: Int, width: CGFloat) -> CGFloat {
        guard activityUnitCount > 1 else {
            return width / 2
        }

        let horizontalInset: CGFloat = 2
        let usableWidth = max(width - (horizontalInset * 2), 1)
        return horizontalInset + (usableWidth * CGFloat(index) / CGFloat(activityUnitCount - 1))
    }

    private var commandLoaderFrames: [String] {
        ["|", "/", "-", "\\"]
    }

    private func cyclicDistance(from index: Int, to activeIndex: Int) -> Int {
        let rawDistance = abs(index - activeIndex)
        return min(rawDistance, activityUnitCount - rawDistance)
    }

    private func signalSweepColor(distance: Int) -> Color {
        if theme == .colorful || theme == .cloud {
            let colors: [Color] = [.cyan, .green, .yellow, .orange, .red, .purple, .blue, .cyan]
            return colors[min(distance, colors.count - 1)]
        }

        return theme.accentColor
    }

    private func matrixCharacters(second: Int) -> [Character] {
        let source = Array("01$#@<>/\\")
        return (0..<activityUnitCount).map { index in
            let value = abs((second &* 31) &+ (index &* 17) &+ (index * index))
            return source[value % source.count]
        }
    }

    private func matrixColor(for index: Int, second: Int) -> Color {
        if theme == .colorful || theme == .cloud {
            let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
            return colors[(second + index) % colors.count]
        }

        return index == second % activityUnitCount ? theme.accentColor : theme.accentColor.opacity(0.65)
    }

    private var dotStyle: AnyShapeStyle {
        if theme == .colorful || theme == .cloud {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }

        return AnyShapeStyle(theme.accentColor)
    }
}

private struct ActivityCapsuleModifier: ViewModifier {
    let theme: TermiFaceTheme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(Capsule().fill(.black.opacity(0.55)))
            .overlay {
                Capsule().stroke(theme.accentColor.opacity(0.65), lineWidth: 1)
            }
    }
}

private extension View {
    func activityCapsule(theme: TermiFaceTheme) -> some View {
        modifier(ActivityCapsuleModifier(theme: theme))
    }
}

private struct PacmanShape: Shape {
    let mouthOpen: Bool

    func path(in rect: CGRect) -> Path {
        let mouthAngle = Angle.degrees(mouthOpen ? 35 : 14)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: mouthAngle,
            endAngle: .degrees(360 - mouthAngle.degrees),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
