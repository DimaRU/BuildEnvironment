/////
////  BuildEnvGenerator.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation

@main
struct BuildEnvGenerator {
    struct Config {
        enum Keywords: String, CaseIterable {
            case name, access, encode
        }
        enum AccessLevel: String, CaseIterable {
            case `public`, `package`, `internal`
            var string: String {
                switch self {
                case .internal: ""
                default: rawValue + " "
                }
            }
        }
        var name: String
        var access: AccessLevel
        var encode: Bool
        
        init() {
            self.name = "BuildEnvironment"
            self.access = .public
            self.encode = false
        }
    }
    
    struct ParseError: Error {
        let line: Int
        let kind: ErrorKind
        enum ErrorKind {
            case separator
            case keyword
            case at
            case accessSpec
            case encodeSpec
            case keyExist(key: String)
            case env(key: String)
            case enclose
        }
    }
    
    
    static func main() {
        guard
            CommandLine.argc >= 3
        else {
            print(
                """
                Usage: \(CommandLine.arguments[0])
                    --output swift-file
                    --env env-file
                    --config config-file
                """,
                to: &stderror)
            exit(EXIT_FAILURE)
        }
        guard
            let swiftFile = getStringArg("--output")
        else {
            print("Required '--output' argument is missing", to: &stderror)
            exit(EXIT_FAILURE)
        }
        guard
            getStringArg("--env") != nil || getStringArg("--config") != nil
        else {
            print("'--env' or '--config' argument is missing", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        var envDict: [String: String] = [:]
        var config = Config()
        var file: String?
        
        do {
            file = getStringArg("--config")
            if let file {
                let content = try String(contentsOf: URL(fileURLWithPath: file), encoding: .utf8)
                config = try parceConfig(content: content, envDict: &envDict)
            }
            
            file = getStringArg("--env")
            if let file {
                let content = try String(contentsOf: URL(fileURLWithPath: file), encoding: .utf8)
                try parceEnv(content: content, envDict: &envDict)
            }
        } catch let error as ParseError {
            let line = error.line + 1
            let errorMessage = switch error.kind {
            case .separator: "no '=' or ':' separator"
            case .keyword: "illegal keyword"
            case .at: "no $ symbol before env variable"
            case .accessSpec: "wrong access spec, must be one of " + Config.AccessLevel.allCases.map{$0.rawValue}.joined(separator: ", ")
            case .encodeSpec: "wrong encode spec, must be yes or no"
            case .keyExist(key: let key): "key \(key) already exits"
            case .env(key: let key): "no environment variable \(key)"
            case .enclose: "string must be surrounded by double quotation marks (\")"
            }
            print("Error in line \(line) of \(file!):", errorMessage, to: &stderror)
            exit(EXIT_FAILURE)
        } catch {
            print("File \(file!) read error \(error)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        
        var content =
            """
            // Code generated from .env file 
            // Don't edit! All changes will be lost.
            
            \(config.access.string)enum \(config.name) {
            
            """
        for (key, value) in envDict {
            if config.encode {
                content += encodedCode(key: key, value: value, config: config)
            } else {
                content += "    \(config.access.string)static let \(key): String = \"\(value)\"\n"
            }
        }
        content += "}\n"
        
        let swiftFileURL = URL(fileURLWithPath: swiftFile)
        
        do {
            try content.write(to: swiftFileURL,
                              atomically: false,
                              encoding: .utf8)
        } catch  {
            print("Write error \(swiftFileURL.path) \(error.localizedDescription)", to: &stderror)
            exit(EXIT_FAILURE)
        }
        print("Created file \(swiftFileURL.path)")
    }
    
    static func encodedCode(key: String, value: String, config: Config) -> String {
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
    \(config.access.string)static let \(key): String = {
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
    
    static func parceEnv(content: String, envDict: inout [String: String]) throws {
        let lines = content
            .split(separator: "\n")
            .map{ $0.trimmingCharacters(in: .whitespaces)}
        for i in lines.indices where !lines[i].isEmpty && lines[i].first != "#" {
            let keyValue = lines[i].split(separator: "=", maxSplits: 1).map({ $0.trimmingCharacters(in: .whitespaces)})
            guard keyValue.count == 2 else {
                throw ParseError(line: i, kind: .separator)
            }
            let value = keyValue[1]
            guard value.first == "\"", value.last == "\"" else {
                throw ParseError(line: i, kind: .enclose)
            }
            envDict[keyValue[0]] = String(value.dropFirst().dropLast())
        }
    }
    
    static func parceConfig(content: String, envDict: inout [String: String]) throws -> Config {
        var config = Config()
        
        let lines = content
            .split(separator: "\n")
            .map{ $0.trimmingCharacters(in: .whitespaces)}
        
        for i in lines.indices where !lines[i].isEmpty && lines[i].first != "#" {
            if lines[i].contains("=") {
                let keyValue = lines[i].split(separator: "=", maxSplits: 1).map({ $0.trimmingCharacters(in: .whitespaces)})
                guard keyValue[1].first == "$" else {
                    throw ParseError(line: i, kind: .at)
                }
                var env = String(keyValue[1].dropFirst())
                var optional = false
                if env.last == "?" {
                    env.removeLast()
                    optional = true
                }
                guard let value = ProcessInfo.processInfo.environment[env] else {
                    if optional {
                        continue
                    } else {
                        throw ParseError(line: i, kind: .env(key: env))
                    }
                }
                guard envDict.append(key: keyValue[0], value: value) else {
                    throw ParseError(line: i, kind: .keyExist(key: keyValue[0]))
                }
            } else if lines[i].contains(":") {
                let keyValue = lines[i].split(separator: ":", maxSplits: 1).map({ $0.trimmingCharacters(in: .whitespaces)})
                guard let keyword = Config.Keywords(rawValue: keyValue[0]) else {
                    throw ParseError(line: i, kind: .keyword)
                }
                switch keyword {
                case .name:
                    config.name = keyValue[1]
                case .access:
                    guard let access = Config.AccessLevel(rawValue: keyValue[1]) else {
                        throw ParseError(line: i, kind: .accessSpec)
                    }
                    config.access = access
                case .encode:
                    guard ["yes", "no"].contains(keyValue[1]) else {
                        throw ParseError(line: i, kind: .encodeSpec)
                    }
                    config.encode = keyValue[1] == "yes"
                }
            } else {
                throw ParseError(line: i, kind: .separator)
            }
        }
        return config
    }
}
