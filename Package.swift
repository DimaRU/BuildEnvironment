// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "BuildEnvironment",
    platforms: [.macOS(.v11), .iOS(.v14), .watchOS(.v7), .tvOS(.v14)],
    products: [
        .plugin(name: "BuildEnvPlugin", targets: ["BuildEnvPlugin"]),
    ],
    targets: [
        .plugin(
            name: "BuildEnvPlugin",
            capability: .buildTool(),
            dependencies: ["BuildEnvGenerator"]
        ),
        .executableTarget(
            name: "BuildEnvGenerator"
        ),
        .executableTarget(
            name: "BuildEnvExample",
            plugins: ["BuildEnvPlugin"]
        ),
    ]
)
