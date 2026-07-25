import Testing
import Foundation
@testable import VoiceTypeKit

/// The promises `docs/LANGUAGES.md` makes about coverage, enforced in code.
/// The published matrix is only trustworthy if adding a locale to the picker
/// can't quietly ship a language no engine can actually transcribe.
@Suite("Dictation languages — coverage")
struct LanguageCoverageTests {

    /// Every engine whose language set is a static model-card fact. Apple's is
    /// runtime-queried (`staticCodes` returns nil), so it can't be asserted here.
    private static let staticEngines: [TranscriptionEngineKind] = [
        .parakeet, .whisperKit, .nemotron,
    ]

    @Test("locales are unique, lowercase-language + region BCP-47 tags")
    func wellFormed() {
        var seen: Set<String> = []
        for language in DictationLanguage.all {
            let parts = language.code.split(separator: "-")
            #expect(parts.count == 2, "\(language.code) is not language-region")
            #expect(parts[0] == parts[0].lowercased(), "\(language.code)")
            #expect(parts[1] == parts[1].uppercased(), "\(language.code)")
            #expect(seen.insert(language.code).inserted, "duplicate \(language.code)")
        }
    }

    /// The picker is curated, not exhaustive: offering a language means at
    /// least one downloadable engine is genuinely good at it. Apple deliberately
    /// doesn't count — its list varies by macOS version, so a language that only
    /// Apple handled would be a dead end for anyone it doesn't cover.
    @Test("every offered language is transcribable by a downloadable engine")
    func everyLanguageHasAnEngine() {
        for language in DictationLanguage.all {
            let engines = Self.staticEngines.filter {
                EngineLanguages.staticCodes(for: $0)?
                    .contains(LanguageTag.code(for: language.code)) == true
            }
            #expect(!engines.isEmpty,
                    "\(language.code) is offered but no downloadable engine supports it")
        }
    }

    /// Whisper is the broad-coverage fallback the resolver leans on, and
    /// `DictationLanguage` documents that it covers every offered language.
    /// Norwegian already broke this once: the picker offers `nb-NO` while
    /// Whisper's tokenizer spells the language "no".
    @Test("Whisper covers every offered language")
    func whisperIsTheFloor() {
        let whisper = EngineLanguages.staticCodes(for: .whisperKit)!
        for language in DictationLanguage.all {
            #expect(whisper.contains(LanguageTag.code(for: language.code)),
                    "Whisper is missing \(language.code)")
        }
    }

    /// A pack is optional — languages without one get `.neutral` — but a pack
    /// for a language the picker doesn't offer is dead code.
    @Test("every language pack corresponds to an offered language")
    func packsAreReachableFromThePicker() {
        let offered = Set(DictationLanguage.all.map { LanguageTag.code(for: $0.code) })
        for pack in LanguagePack.all {
            #expect(offered.contains(pack.code),
                    "pack \(pack.code) has no matching entry in DictationLanguage.all")
        }
    }
}
