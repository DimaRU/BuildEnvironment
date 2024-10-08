/////
////  DictionaryExtensions.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    mutating func append(key: String, value: String) -> Bool {
        guard !self.keys.contains(key) else {
            return false
        }
        self[key] = value
        return true
    }
}
