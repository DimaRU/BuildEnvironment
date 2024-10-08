/////
////  GetArgument.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation

/// Extract string argument
/// - Parameter arg: Argument name
/// - Returns: String or nil if not exist
func getStringArg(_ arg: String) -> String? {
    guard
        let index = CommandLine.arguments.firstIndex(of: arg)
    else { return nil }
    return CommandLine.arguments[safe: index + 1]
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
