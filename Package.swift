// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BasiliskControl",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "BasiliskControl", targets: ["BasiliskControl"])],
    targets: [
        .target(name: "BasiliskHID", publicHeadersPath: "include", linkerSettings: [
            .linkedFramework("IOKit", .when(platforms: [.macOS])),
            .linkedFramework("CoreFoundation", .when(platforms: [.macOS]))
        ]),
        .executableTarget(name: "BasiliskControl", dependencies: ["BasiliskHID"])
    ]
)
