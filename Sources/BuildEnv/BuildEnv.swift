/////
////  BuildEnv.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation

@main
struct GenerateBuildEnvironment {
    static func main() {
        if CommandLine.argc != 3 {
            print("usage: \(CommandLine.arguments[0]) env-file swift-file", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        let envFile = CommandLine.arguments[1]
        let swiftFile = CommandLine.arguments[2]
        
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
            public struct BuildEnvironment {
                init() { fatalError() }
            
            """
        for (key, value) in envDict {
            content += "    public static let \(key): String = \"\(value)\"\n"
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
}
