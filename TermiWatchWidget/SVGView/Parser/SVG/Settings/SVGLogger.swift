//
//  SVGLogger.swift
//  SVGView
//
//  Created by Yuri Strot on 26.05.2022.
//

import Foundation
import OSLog

private let svgLogger = Logger(subsystem: "com.github.lunf.zShellWatch", category: "SVG")

public class SVGLogger {

    public static let console = SVGLogger()

    public func log(message: String) {
        svgLogger.error("\(message, privacy: .public)")
    }

    public func log(error: Error) {
        log(message: error.localizedDescription)
    }

}
