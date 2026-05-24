// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClickLight",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClickLight", targets: ["ClickLight"])
    ],
    targets: [
        .executableTarget(
            name: "ClickLight",
            path: "Sources/ClickLight"
        )
    ]
)
