//
//  TermiFaceView.swift
//  TermiWatchWidget
//

import SwiftUI
import WidgetKit

struct TermiFaceView: View {
    let context: TimelineProviderContext?
    var weather: WeatherViewInfo
    var health: HealthInfo
    var lines: [TermiFaceLine] = selectedFaceLines()
    var theme: TermiFaceTheme = selectedFaceTheme()
    var animation: TermiFaceAnimation = selectedFaceAnimation()
    var terminalUser: String = terminalName()
    var machine: String = machineName()

    init(
        context: TimelineProviderContext?,
        weather: WeatherViewInfo,
        health: HealthInfo,
        lines: [TermiFaceLine] = selectedFaceLines(),
        theme: TermiFaceTheme = selectedFaceTheme(),
        animation: TermiFaceAnimation = selectedFaceAnimation(),
        terminalUser: String = terminalName(),
        machine: String = machineName()
    ) {
        self.context = context
        self.weather = weather
        self.health = health
        self.lines = lines
        self.theme = theme
        self.animation = animation
        self.terminalUser = terminalUser
        self.machine = machine
    }

    init(context: TimelineProviderContext?, snapshot: FaceDataSnapshot, configuration: WatchFaceConfiguration) {
        self.init(
            context: context,
            weather: snapshot.weather,
            health: snapshot.health,
            lines: configuration.lines,
            theme: configuration.theme,
            animation: configuration.animation,
            terminalUser: configuration.terminalUser,
            machine: configuration.machineName
        )
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: theme == .binary ? 1 : 60)) { timeline in
            let rowHeight = faceBaseRowHeight()
            let visibleLines = availableFaceLines(from: lines)

            Group {
                if theme == .binary {
                    BinaryWatchFaceView(date: timeline.date, theme: theme)
                } else {
                    VStack(alignment: .leading, spacing: qFaceRowSpacing) {
                        ForEach(visibleLines) { line in
                            faceRow(line, date: timeline.date)
                                .frame(height: rowHeight * termiFaceLineHeightWeight(line, theme: theme))
                        }
                    }
                    .padding(.top, qFacePaddingTop)
                    .padding(.horizontal, qFacePaddingHorizontal)
                    .padding(.bottom, qFacePaddingBottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .environment(\.termiFaceTheme, theme)
#if os(watchOS)
            .overlay(alignment: .topLeading) {
                TermiCornerActivityView(theme: theme, animation: animation)
                    .padding(.top, cornerActivityTopPadding)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
#endif
            .clipped()
        }
    }

    private var cornerActivityTopPadding: CGFloat {
        4
    }

    private func faceBaseRowHeight() -> CGFloat {
        let defaultHeight = qRowHeight + 0.5
        let visibleLines = availableFaceLines(from: lines)
        let totalLineWeight = visibleLines.reduce(CGFloat(0)) { $0 + termiFaceLineHeightWeight($1, theme: theme) }

        guard let displayHeight = context?.displaySize.height, totalLineWeight > 0 else {
            return defaultHeight
        }

        let totalSpacing = CGFloat(max(0, visibleLines.count - 1)) * qFaceRowSpacing
        let verticalPadding = qFacePaddingTop + qFacePaddingBottom
        return ((displayHeight - verticalPadding - totalSpacing) / totalLineWeight) + 0.5
    }
}
