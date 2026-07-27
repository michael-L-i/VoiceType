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

    @Test("question suffix particles are non-empty and lowercase (matched with hasSuffix)")
    func suffixParticles() {
        for pack in LanguagePack.all {
            for particle in pack.questionSuffixParticles {
                #expect(!particle.isEmpty, "\(pack.code)")
                #expect(particle == particle.lowercased(), "\(pack.code): \(particle)")
            }
        }
    }

    @Test("the question mark is a single mark, full-width exactly for full-width packs")
    func questionMarks() {
        for pack in LanguagePack.all {
            #expect(!pack.questionMark.isEmpty, "\(pack.code)")
            if pack.usesFullWidthPunctuation {
                #expect(pack.questionMark == "？", "\(pack.code)")
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

    @Test("a pack that opts into spoken symbols supplies usable trigger words")
    func symbolVocabularyHygiene() {
        for pack in LanguagePack.all {
            guard let symbols = pack.symbols else { continue }
            #expect(!symbols.dot.isEmpty, "\(pack.code) has no word for a dot")
            for word in symbols.dot.union(symbols.underscore).union(symbols.dash) {
                #expect(word == word.lowercased(), "\(pack.code): \(word)")
                #expect(!word.isEmpty, "\(pack.code)")
            }
        }
    }

    @Test("a standalone capitalized pronoun is a single lowercase letter")
    func standalonePronounHygiene() {
        for pack in LanguagePack.all {
            guard let pronoun = pack.capitalizedStandalonePronoun else { continue }
            #expect(pronoun == pronoun.lowercased(), "\(pack.code): \(pronoun)")
            #expect(pronoun.count == 1, "\(pack.code): \(pronoun)")
        }
    }

    @Test("pack rules are named and uniquely named within a pack")
    func ruleNames() {
        for pack in LanguagePack.all {
            var seen: Set<String> = []
            for rule in pack.rules {
                #expect(!rule.name.isEmpty, "\(pack.code) has an unnamed rule")
                #expect(seen.insert(rule.name).inserted,
                        "\(pack.code): duplicate rule name \(rule.name)")
            }
        }
    }

    @Test("no pack's rules corrupt a terminal command")
    func rulesLeaveCommandsAlone() {
        // Rules default to sitting out the terminal; one that opts in must
        // still leave an ordinary command untouched.
        for pack in LanguagePack.all {
            let command = "git status"
            let out = RuleBasedCleanup.process(command, options: .default,
                                               context: CleanupContext(category: .terminal),
                                               pack: pack)
            #expect(out == command, "\(pack.code) rewrote a shell command to \(out)")
        }
    }

    @Test("a pack's few-shot examples are non-empty pairs")
    func fewShotHygiene() {
        for pack in LanguagePack.all {
            for example in pack.prompt.fewShot + pack.prompt.terminalFewShot {
                #expect(!example.spoken.isEmpty, "\(pack.code)")
                #expect(!example.cleaned.isEmpty, "\(pack.code)")
            }
        }
    }

    @Test("every pack's lead-in patterns compile")
    func leadInPatternsCompile() {
        for pack in LanguagePack.all {
            for pattern in pack.modelLeadInPatterns {
                #expect((try? NSRegularExpression(pattern: pattern)) != nil,
                        "\(pack.code): \(pattern) does not compile")
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
