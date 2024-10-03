/////
////  BuildEnvFile.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation

@main
struct GenerateBuildEnvironment {
    static func main() {
        guard CommandLine.argc >= 3 else {
            print("usage: \(CommandLine.arguments[0]) env-file swift-file [-e]", to: &stderror)
            exit(EXIT_FAILURE)
        }
        let envFile = CommandLine.arguments[1]
        let swiftFile = CommandLine.arguments[2]
        
        let encode: Bool
        if CommandLine.argc == 3 {
            encode = false
        } else if CommandLine.argc == 4, CommandLine.arguments[3] == "-e" {
            encode = true
        } else {
            print("usage: \(CommandLine.arguments[0]) env-file swift-file [-e]", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        guard FileManager.default.fileExists(atPath: envFile) else {
            print("env file not found: \(envFile)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        let env: String
        do {
            env = try String.init(contentsOf: URL(fileURLWithPath: envFile), encoding: .utf8)
        } catch {
            print("Failed to read \(envFile): \(error)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        var envDict: [String: String] = [:]
        let envList = env.split(separator: "\n")
        for envLine in envList where !envLine.isEmpty && envLine.first != "#" {
            let keyValue = envLine.split(separator: "=", maxSplits: 1).map({ $0.trimmingCharacters(in: .whitespaces)})
            guard keyValue.count == 2 else {
                print("Invalid env line: \(envLine)", to: &stderror)
                exit(EXIT_FAILURE)
            }
            envDict[keyValue[0]] = keyValue[1]
        }
        
        var content =
            """
            // Code generated from .env file 
            // Don't edit! All changes will be lost.
            
            public enum BuildEnvironment {
            
            """
        for (key, value) in envDict {
            if encode {
                content += encodedCode(key: key, value: value)
            } else {
                content += "    public static let \(key): String = \"\(value)\"\n"
            }
        }
        content += "}\n"
        
        let swiftFileURL = URL(fileURLWithPath: swiftFile)
        
        do {
            try content.write(to: swiftFileURL,
                              atomically: false,
                              encoding: .utf8)
        } catch  {
            print("Write error \(swiftFileURL.absoluteString) \(error.localizedDescription)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        print("Created file \(swiftFileURL.path)")
    }
    
    static func encodedCode(key: String, value: String) -> String {
        guard var encrypted = value.data(using: .utf8) else {
            print("Non-utf8 string value for key \(key)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        var cipher: [UInt8] = []
        encrypted.indices.forEach {
            cipher.append(UInt8.random(in: UInt8.min...UInt8.max))
            encrypted[$0] = encrypted[$0] ^ cipher[$0]
        }
        let encryptedText = encrypted.map{ String($0) }.joined(separator: ", ")
        let cipherText = cipher.map{ String($0) }.joined(separator: ", ")
        let code = """
    public static let \(key): String = {
        let encrypted: [UInt8] = [\(encryptedText), \(cipherText)]
        let count = encrypted.count / 2
        return String(unsafeUninitializedCapacity: count) { ptr in
            (0..<count).forEach { ptr[$0] = encrypted[$0] ^ encrypted[$0 + count] }
            return count
        }
    }()

"""
        return code
    }
}
