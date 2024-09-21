// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuildEnvironment",
    products: [
        .executable(name: "BuildEnv", targets: ["BuildEnv"]),
        .plugin(name: "BuildEnvPlugin", targets: ["BuildEnvPlugin"]),
    ],
    targets: [
        .executableTarget(
            name: "BuildEnv"
            ),
        .executableTarget(
            name: "BuildEnvExample",
            dependencies: ["BuildEnv"],
            plugins: ["BuildEnvPlugin"]
        ),
        .plugin(
            name: "BuildEnvPlugin",
            capability: .buildTool(),
            dependencies: ["BuildEnv"]
        ),
    ]
)
