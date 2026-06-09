// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceType",
    platforms: [
        // macOS 26 ("Tahoe") is required for on-device SpeechTranscriber and
        // FoundationModels. Older systems are out of scope (Mac-only, latest-OS first).
        .macOS("26.0")
    ],
    products: [
        .executable(name: "VoiceType", targets: ["VoiceType"]),
        .library(name: "VoiceTypeKit", targets: ["VoiceTypeKit"]),
    ],
    targets: [
        // Pure, UI-agnostic, dependency-free core logic. Fully unit-testable.
        // Parallel feature work builds against the contracts declared here.
        .target(
            name: "VoiceTypeKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The macOS app: menu-bar shell, hotkey, audio capture, system engines,
        // text injection, settings UI. Depends only on the Kit contracts.
        .executableTarget(
            name: "VoiceType",
            dependencies: ["VoiceTypeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VoiceTypeKitTests",
            dependencies: ["VoiceTypeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
