//
//  WatchFacePreview.swift
//  TermiWatchWidget
//

import SwiftUI

struct WatchFacePreview: View {
    let viewModel: QTermiViewModel
    let configuration: WatchFaceConfiguration
    private let renderer = TerminalWatchFaceRenderer()

    private var theme: TermiFaceTheme {
        configuration.theme
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            renderer.render(
                WatchFaceRenderRequest(
                    context: nil,
                    snapshot: viewModel.snapshot,
                    configuration: configuration
                )
            )
            .foregroundStyle(theme.textColor)
            .padding(.top, watchPreviewStatusContentInset)

            TermiCornerActivityView(theme: theme, animation: configuration.animation)
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
