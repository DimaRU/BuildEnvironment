// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuildEnvironment",
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
