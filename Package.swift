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
    dependencies: [
        // SwiftWhisper wraps whisper.cpp and accepts `[Float]` 16 kHz mono audio,
        // which is exactly our `PCMBuffer.samples` shape — no resampling glue.
        // The library has no tagged release newer than 1.2.0, so we pin to a
        // specific master commit (its README points consumers at branch commits).
        .package(url: "https://github.com/exPHAT/SwiftWhisper",
                 revision: "c340197966ebd264f3135d3955874b40f8ed58bc"),
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
            dependencies: [
                "VoiceTypeKit",
                .product(name: "SwiftWhisper", package: "SwiftWhisper"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VoiceTypeKitTests",
            dependencies: ["VoiceTypeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
