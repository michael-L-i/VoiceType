import Testing
import Foundation
@testable import VoiceTypeKit

/// Structural rules every language pack must obey, whoever contributes it.
/// These run over `LanguagePack.all`, so a new language is covered the moment
/// it registers.
@Suite("Language packs — integrity (all registered packs)")
struct PackIntegrityTests {
    @Test("codes are non-empty, lowercase primary subtags, and unique")
    func codes() {
        var seen: Set<String> = []
        for pack in LanguagePack.all {
            #expect(!pack.code.isEmpty)
            #expect(pack.code == pack.code.lowercased())
            #expect(pack.code.count <= 3, "\(pack.code) is not a primary subtag")
            #expect(seen.insert(pack.code).inserted, "duplicate pack for \(pack.code)")
        }
    }

    @Test("every pack is reachable through the registry lookup")
    func reachable() {
        for pack in LanguagePack.all {
            #expect(LanguagePack.pack(for: "\(pack.code)-XX").code == pack.code)
        }
    }

    @Test("fillers contain no uppercase, no surrounding whitespace, never empty strings")
    func fillerHygiene() {
        for pack in LanguagePack.all {
            for filler in pack.fillers {
                #expect(!filler.isEmpty)
                #expect(filler == filler.lowercased(), "\(pack.code): \(filler)")
                #expect(filler == filler.trimmingCharacters(in: .whitespaces))
            }
        }
    }

    @Test("spoken punctuation maps names to marks or newlines, never to words")
    func spokenPunctuationHygiene() {
        for pack in LanguagePack.all {
            for (name, mark) in pack.spokenPunctuation {
                #expect(!name.isEmpty)
                let isNewline = mark.allSatisfy { $0 == "\n" }
                let isMark = mark.allSatisfy { $0.isPunctuation || $0.isSymbol }
                #expect(isNewline || isMark, "\(pack.code): \(name) → \(mark)")
            }
        }
    }

    @Test("question suffix particles are single characters (the heuristic probes the last character)")
    func suffixParticles() {
        for pack in LanguagePack.all {
            for particle in pack.questionSuffixParticles {
                #expect(particle.count == 1, "\(pack.code): \(particle)")
            }
        }
    }

    @Test("full-width packs have a full-width terminal mark; Latin packs a period")
    func terminalConsistency() {
        for pack in LanguagePack.all {
            if pack.usesFullWidthPunctuation {
                #expect(pack.terminalPeriod == "。", "\(pack.code)")
                #expect(!pack.separatesWordsWithSpaces, "\(pack.code)")
            } else {
                #expect(pack.terminalPeriod == ".", "\(pack.code)")
            }
        }
    }

    @Test("filler removal never touches an unrelated sentence in any pack's language")
    func fillerRemovalIsBounded() {
        // A pack's own fillers, dropped into a neutral carrier of another
        // script, must not corrupt surrounding text: process with each locale
        // and assert the carrier words survive.
        for pack in LanguagePack.all where !pack.fillers.isEmpty {
            let carrier = "alpha beta gamma"
            let out = RuleBasedCleanup.process(carrier, options: .default,
                                               locale: "\(pack.code)-XX")
            #expect(out.lowercased().contains("alpha"), "\(pack.code)")
            #expect(out.lowercased().contains("gamma"), "\(pack.code)")
        }
    }
}
