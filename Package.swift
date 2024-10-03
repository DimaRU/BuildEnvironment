// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "BuildEnvironment",
    platforms: [.macOS(.v11), .iOS(.v14), .watchOS(.v7), .tvOS(.v14)],
    products: [
        .plugin(name: "BuildEnvFilePlugin", targets: ["BuildEnvFilePlugin"]),
    ],
    targets: [
        .plugin(
            name: "BuildEnvFilePlugin",
            capability: .buildTool(),
            dependencies: ["BuildEnvFile"]
        ),
        .executableTarget(
            name: "BuildEnvFile"
        ),
        .executableTarget(
            name: "BuildEnvExample",
            dependencies: ["BuildEnvFile"],
            plugins: ["BuildEnvFilePlugin"]
        ),
    ]
)
