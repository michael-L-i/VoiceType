import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Transcription engine metadata")
struct EngineMetadataTests {
    @Test("only Apple is built-in; downloadable engines require a download")
    func downloadRequirement() {
        #expect(TranscriptionEngineKind.appleOnDevice.requiresDownload == false)
        #expect(TranscriptionEngineKind.parakeet.requiresDownload == true)
    }

    @Test("downloadable engines advertise a size; the built-in one doesn't")
    func downloadSizes() {
        #expect(TranscriptionEngineKind.appleOnDevice.approxDownloadSize == nil)
        #expect(TranscriptionEngineKind.parakeet.approxDownloadSize != nil)
    }

    @Test("Parakeet surfaces its required NVIDIA / CC-BY attribution")
    func parakeetAttribution() {
        let attribution = TranscriptionEngineKind.parakeet.attribution
        #expect(attribution?.contains("NVIDIA") == true)
    }

    @Test("vendors map to the right company")
    func vendors() {
        #expect(TranscriptionEngineKind.appleOnDevice.vendor == .apple)
        #expect(TranscriptionEngineKind.parakeet.vendor == .nvidia)
    }

    @Test("every kind has a non-empty name, summary, and features")
    func displayStrings() {
        for kind in TranscriptionEngineKind.allCases {
            #expect(!kind.displayName.isEmpty)
            #expect(!kind.summary.isEmpty)
            #expect(!kind.features.isEmpty)
        }
    }
}

@Suite("Model availability state")
struct ModelAvailabilityTests {
    @Test("built-in and ready are usable; the rest are not")
    func readiness() {
        #expect(ModelAvailability.builtIn.isReady)
        #expect(ModelAvailability.ready.isReady)
        #expect(!ModelAvailability.notDownloaded.isReady)
        #expect(!ModelAvailability.downloading(0.5).isReady)
        #expect(!ModelAvailability.failed("x").isReady)
    }

    @Test("only the downloading state reports in-flight")
    func downloading() {
        #expect(ModelAvailability.downloading(nil).isDownloading)
        #expect(ModelAvailability.downloading(0.3).isDownloading)
        #expect(!ModelAvailability.ready.isDownloading)
        #expect(!ModelAvailability.builtIn.isDownloading)
    }
}
