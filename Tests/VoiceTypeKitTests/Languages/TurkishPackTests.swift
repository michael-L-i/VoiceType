import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Turkish policy")
struct TurkishPackPolicyTests {
    @Test("only non-lexical closed-vowel pauses are deterministic fillers")
    func fillersAreConservative() {
        let tr = LanguagePack.turkish
        #expect(tr.fillers == ["ıı", "ııı", "ıııı"])
        for meaningful in ["şey", "yani", "işte", "falan", "filan", "eee", "hmm"] {
            #expect(!tr.fillers.contains(meaningful))
        }
    }

    @Test("Turkish casing and symbol ownership respect shared pack invariants")
    func packShape() {
        let tr = LanguagePack.turkish
        #expect(tr.casingLocaleIdentifier == "tr_TR")
        #expect(tr.uppercased("i") == "İ")
        #expect(tr.uppercased("ı") == "I")
        #expect(tr.symbols == nil)
        #expect(tr.capitalizedStandalonePronoun == nil)
    }

    @Test("prompt guidance fills every Turkish-specific section without few-shot leakage")
    func promptGuidance() {
        let prompt = LanguagePack.turkish.prompt
        #expect(prompt.fillerExamples != nil)
        #expect(prompt.capitalizationRule != nil)
        #expect(prompt.codeRendering != nil)
        #expect(prompt.terminalGuidance != nil)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule != nil)
        #expect(prompt.addendum != nil)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Turkish")
struct TurkishRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "tr-TR")
    }

    @Test("non-lexical pauses are removed without deleting meaningful lookalikes")
    func fillers() {
        #expect(clean("ııı bugün toplantıya gideceğiz") == "Bugün toplantıya gideceğiz.")
        #expect(clean("şey bu şey çok önemli") == "Şey bu şey çok önemli.")
        #expect(clean("yani sonuç değişmedi") == "Yani sonuç değişmedi.")
    }

    @Test("sentence capitalization uses dotted and dotless Turkish I")
    func localeAwareCasing() {
        #expect(clean("istanbul bugün sıcak") == "İstanbul bugün sıcak.")
        #expect(clean("ılık bir akşam") == "Ilık bir akşam.")
    }

    @Test("unambiguous spoken punctuation renders with Turkish spacing")
    func spokenPunctuation() {
        #expect(clean("yarın görüşürüz soru işareti") == "Yarın görüşürüz?")
        #expect(
            clean("birinci virgül işareti ikinci noktalı virgül üçüncü")
                == "Birinci, ikinci; üçüncü.")
        #expect(
            clean("tırnak aç Merhaba tırnak kapat dedi")
                == "“Merhaba” dedi.")
    }

    @Test("spoken punctuation is idempotent when a terminal mark already exists")
    func spokenPunctuationIdempotent() {
        #expect(clean("yarın görüşürüz? soru işareti") == "Yarın görüşürüz?")
    }

    @Test("decimal commas survive the shared comma-spacing pass")
    func decimalComma() {
        #expect(clean("oran 3,14 oldu") == "Oran 3,14 oldu.")
        #expect(clean("fiyat 1.250,50 lira") == "Fiyat 1.250,50 lira.")
    }

    @Test("percent, per-mille, and lira signs attach to following numbers")
    func rateAndCurrencySigns() {
        #expect(
            clean("oran yüzde işareti 25 fiyat türk lirası işareti 125,50")
                == "Oran %25 fiyat ₺125,50.")
        #expect(clean("oran binde işareti 5") == "Oran ‰5.")
    }

    @Test("abbreviation periods do not create false sentence boundaries")
    func abbreviations() {
        #expect(
            clean("örnekler elma vb. meyveler içeriyor")
                == "Örnekler elma vb. meyveler içeriyor.")
        #expect(clean("liste elma vb.") == "Liste elma vb.")
    }

    @Test("dictated line and paragraph breaks survive the Latin spacing pass")
    func lineBreaks() {
        #expect(clean("birinci yeni satır ikinci") == "Birinci\nikinci.")
        #expect(clean("ilk bölüm yeni paragraf ikinci bölüm") == "İlk bölüm\n\nikinci bölüm.")
    }

    @Test("sentence-final Turkish question particles gain a question mark")
    func questionParticles() {
        #expect(clean("yarın geliyor musun") == "Yarın geliyor musun?")
        #expect(clean("toplantı gelecek miydi") == "Toplantı gelecek miydi?")
        #expect(clean("bu eski bir resim") == "Bu eski bir resim.")
    }

    @Test("a conservative interrogative opener gains a question mark")
    func questionOpener() {
        #expect(clean("neden geciktin") == "Neden geciktin?")
    }

    @Test("known spoken file extensions render while prose nokta remains a word")
    func spokenDot() {
        #expect(clean("main nokta swift dosyasını aç") == "main.swift dosyasını aç.")
        #expect(clean("bu önemli bir nokta com değil") == "Bu önemli bir nokta com değil.")
    }

    @Test("ambiguous alt çizgi renders only in code-oriented contexts")
    func spokenUnderscore() {
        #expect(
            clean("max alt çizgi retries değerini ayarla", category: .codeEditor)
                == "max_retries değerini ayarla.")
        #expect(clean("metindeki alt çizgi önemlidir") == "Metindeki alt çizgi önemlidir.")
    }

    @Test("spoken brackets render compactly in a code editor")
    func spokenBrackets() {
        #expect(
            clean("print parantez aç x virgül y parantez kapat", category: .codeEditor)
                == "print(x, y)")
    }

    @Test("embedded file names and identifiers keep their original casing")
    func embeddedTechnicalText() {
        #expect(clean("main.swift dosyasını aç") == "main.swift dosyasını aç.")
        #expect(clean("VoiceType bugün güncellendi") == "VoiceType bugün güncellendi.")
    }

    @Test("terminal dictation renders flags and paths without prose cleanup")
    func terminalCommand() {
        #expect(
            clean(
                "git checkout tire b feature eğik çizgi lang tire tire force",
                category: .terminal)
                == "git checkout -b feature/lang --force")
        #expect(
            clean("cd tilde eğik çizgi projeler eğik çizgi VoiceType", category: .terminal)
                == "cd ~/projeler/VoiceType")
    }

    @Test("terminal prose-looking symbol phrases stay unchanged unless shell-safe")
    func terminalSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(
            clean("echo yeni satır", category: .terminal)
                == "echo yeni satır")
    }
}

@Suite("Cleanup polish — Turkish model output")
struct TurkishPolishTests {
    @Test("model output gets locale-aware capitalization and decimal preservation")
    func casingAndDecimal() {
        #expect(
            CleanupPolish.apply("istanbul’da oran 3,14.", options: .default, locale: "tr-TR")
                == "İstanbul’da oran 3,14.")
    }

    @Test("model output receives the Turkish spoken-symbol repair")
    func technicalRepair() {
        #expect(
            CleanupPolish.apply(
                "main nokta swift dosyasını aç.",
                options: .default,
                context: CleanupContext(category: .codeEditor),
                locale: "tr-TR")
                == "main.swift dosyasını aç.")
    }

    @Test("Turkish model lead-ins are stripped")
    func sanitizerLeadIn() {
        #expect(
            CleanupSanitizer.strip(
                "Elbette, işte düzeltilmiş metin: Bugün toplantıya gidiyoruz.",
                locale: "tr-TR")
                == "Bugün toplantıya gidiyoruz.")
    }
}
