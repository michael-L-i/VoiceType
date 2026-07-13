// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceType",
    defaultLocalization: "en",
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
        // FluidAudio: native Swift SDK that runs NVIDIA Parakeet as CoreML on the
        // Apple Neural Engine. Our on-device Parakeet transcription path.
        .package(url: "https://github.com/FluidInference/FluidAudio",
                 from: "0.12.4"),
        // WhisperKit (Argmax): OpenAI Whisper on CoreML/ANE. Powers the small,
        // fast Whisper Base option.
        .package(url: "https://github.com/argmaxinc/WhisperKit",
                 from: "0.9.0"),
        // Sparkle: in-app auto-updates via a signed appcast (EdDSA). Standard
        // updater for non-App-Store Mac apps.
        .package(url: "https://github.com/sparkle-project/Sparkle",
                 from: "2.6.0"),
    ],
    targets: [
        // Pure, UI-agnostic, dependency-free core logic. Fully unit-testable.
        // Parallel feature work builds against the contracts declared here.
        .target(
            name: "VoiceTypeKit",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The macOS app: Dock-app shell, hotkey, audio capture, system engines,
        // text injection, settings UI. Depends only on the Kit contracts.
        .executableTarget(
            name: "VoiceType",
            dependencies: [
                "VoiceTypeKit",
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            // Localized UI strings (<lang>.lproj/Localizable.strings). SwiftPM
            // compiles these into the VoiceType_VoiceType resource bundle,
            // which Scripts/build-app.sh copies into the .app.
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VoiceTypeKitTests",
            dependencies: ["VoiceTypeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Dev-only eval harness: runs transcripts through the production cleanup
        // prompt against the real on-device FoundationModels model and prints
        // per-case results with deterministic faithfulness metrics. Not part of
        // the app bundle. Usage: swift run CleanupEval Scripts/cleanup-eval/cases.json
        .executableTarget(
            name: "CleanupEval",
            dependencies: ["VoiceTypeKit"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
