//
//  WatchFaceConfiguration.swift
//  TermiWatchWidget
//

import Foundation

struct WatchFaceConfiguration: Codable, Equatable {
    var terminalUser: String
    var machineName: String
    var lines: [TermiFaceLine]
    var theme: TermiFaceTheme
    var animation: TermiFaceAnimation

    init(
        terminalUser: String = terminalName(),
        machineName machineNameValue: String = "local",
        lines: [TermiFaceLine] = selectedFaceLines(),
        theme: TermiFaceTheme = selectedFaceTheme(),
        animation: TermiFaceAnimation = selectedFaceAnimation()
    ) {
        self.terminalUser = terminalUser
        self.machineName = machineNameValue
        self.lines = lines
        self.theme = theme
        self.animation = animation
    }
}
