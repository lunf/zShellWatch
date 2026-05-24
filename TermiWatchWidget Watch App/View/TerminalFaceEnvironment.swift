//
//  TerminalFaceEnvironment.swift
//  TermiWatchWidget
//

import SwiftUI

private struct TermiFaceThemeKey: EnvironmentKey {
    static let defaultValue: TermiFaceTheme = .default
}

extension EnvironmentValues {
    var termiFaceTheme: TermiFaceTheme {
        get { self[TermiFaceThemeKey.self] }
        set { self[TermiFaceThemeKey.self] = newValue }
    }
}
