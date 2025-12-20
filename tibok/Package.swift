// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tibok",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "tibok", targets: ["tibok"])
    ],
    dependencies: [
        // Markdown parsing (Apple's official Swift Markdown)
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),

        // Syntax highlighting for code blocks
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.0"),

        // Auto-update framework for macOS apps
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "tibok",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Highlightr", package: "Highlightr"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "tibok",
            exclude: ["Resources/tibok.entitlements", "Resources/Info.plist", "Resources/IconLayers"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/katex")
            ]
        ),
        .testTarget(
            name: "tibokTests",
            dependencies: [
                .target(name: "tibok"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Highlightr", package: "Highlightr"),
            ],
            path: "tibokTests"
        ),
    ]
)
