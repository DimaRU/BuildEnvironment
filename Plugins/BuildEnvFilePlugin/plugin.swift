/////
////  plugin.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import PackagePlugin
import Foundation

@main
struct BuildEnvPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let inputFile = context.package.directory.appending(".env")
        guard FileManager.default.fileExists(atPath: inputFile.string) else {
            Diagnostics.warning("No \(inputFile) file found.")
            return []
        }
        let outputFile = context.pluginWorkDirectory.appending("BuildEnvironment.swift")
        
        let command = Command.buildCommand(
            displayName: "Generating \(outputFile) in \(context.pluginWorkDirectory)",
            executable: try context.tool(named: "BuildEnvFile").path,
            arguments: [ inputFile,  outputFile, "-e" ],
            inputFiles: [inputFile],
            outputFiles: [outputFile]
        )
        return [command]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension BuildEnvPlugin: XcodeBuildToolPlugin {
    
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputFile = context.xcodeProject.directory.appending(".env")
        guard FileManager.default.fileExists(atPath: inputFile.string) else {
            Diagnostics.warning("No \(inputFile) file found.")
            return []
        }
        let outputFile = context.pluginWorkDirectory.appending("BuildEnvironment.swift")
        
        let command = Command.buildCommand(
            displayName: "Generating \(outputFile) in \(context.pluginWorkDirectory)",
            executable: try context.tool(named: "BuildEnvFile").path,
            arguments: [ inputFile,  outputFile, "-e" ],
            inputFiles: [inputFile],
            outputFiles: [outputFile]
        )
        return [command]
    }
}
#endif
