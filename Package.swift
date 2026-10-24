// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Caffeinate",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Caffeinate", targets: ["Caffeinate"])],
    targets: [
        .target(name: "CaffeinateCore"),
        .executableTarget(name: "Caffeinate", dependencies: ["CaffeinateCore"]),
        .testTarget(name: "CaffeinateCoreTests", dependencies: ["CaffeinateCore"]),
    ]
)
