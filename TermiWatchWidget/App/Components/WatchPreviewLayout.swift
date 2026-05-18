//
//  WatchPreviewLayout.swift
//  TermiWatchWidget
//

import SwiftUI

let watchPreviewWidth: CGFloat = 200
let watchPreviewMinimumHeight: CGFloat = 220
let watchPreviewCornerRadius: CGFloat = 36
let watchPreviewControlGap: CGFloat = 16
let watchPreviewStatusPadding: CGFloat = 14
let watchPreviewAnimationTopInset: CGFloat = 36
let watchPreviewStatusContentInset: CGFloat = 38
let watchPreviewContentInset: CGFloat = 8
let themePickerTopInset: CGFloat = 8

func watchPreviewHeight(lines: [TermiFaceLine], theme: TermiFaceTheme) -> CGFloat {
    let visibleLineWeight = max(lines.reduce(CGFloat(0)) { $0 + termiFaceLineHeightWeight($1, theme: theme) }, 1)
    let rowHeight = qRowHeight + 0.5
    let rowSpacing = CGFloat(max(lines.count - 1, 0)) * qFaceRowSpacing
    let contentHeight = qFacePaddingTop + qFacePaddingBottom + watchPreviewStatusContentInset + (visibleLineWeight * rowHeight) + rowSpacing
    return max(watchPreviewMinimumHeight, ceil(contentHeight + watchPreviewContentInset))
}

func watchPreviewReservedHeight(lines: [TermiFaceLine]) -> CGFloat {
    TermiFaceTheme.allCases
        .map { watchPreviewHeight(lines: lines, theme: $0) }
        .max() ?? watchPreviewMinimumHeight
}
