//
//  TermiFaceAnimation.swift
//  TermiWatchWidget
//

import Foundation

enum TermiFaceAnimation: String, CaseIterable, Identifiable, Codable {
    case dotLine
    case matrixText
    case pacman
    case terminalCursor
    case commandLoader
    case signalSweep
    case none

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .dotLine: return "Dot Line"
        case .matrixText: return "Matrix Text"
        case .pacman: return "Pacman"
        case .terminalCursor: return "Terminal Cursor"
        case .commandLoader: return "Command Loader"
        case .signalSweep: return "Signal Sweep"
        case .none: return "No Animation"
        }
    }

    var systemImage: String {
        switch self {
        case .dotLine: return "ellipsis"
        case .matrixText: return "textformat.123"
        case .pacman: return "circle.lefthalf.filled"
        case .terminalCursor: return "cursorarrow"
        case .commandLoader: return "terminal"
        case .signalSweep: return "waveform.path"
        case .none: return "eye.slash"
        }
    }
}

func selectedFaceAnimation(userDefaults: UserDefaults? = qUserdefaults) -> TermiFaceAnimation {
    guard let rawValue = userDefaults?.string(forKey: qFaceAnimationKey),
          let animation = TermiFaceAnimation(rawValue: rawValue) else {
        return .dotLine
    }

    return animation
}

func saveSelectedFaceAnimation(_ animation: TermiFaceAnimation, userDefaults: UserDefaults? = qUserdefaults) {
    userDefaults?.set(animation.rawValue, forKey: qFaceAnimationKey)
    userDefaults?.synchronize()
}
