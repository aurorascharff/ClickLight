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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ClickLight",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/ClickLight"
        )
    ]
)
