import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Maltese policy")
struct MaltesePackPolicyTests {
    @Test("only non-lexical filled pauses are deterministic")
    func fillerPolicy() {
        let mt = LanguagePack.maltese
        #expect(mt.fillers == ["ee", "em", "emm", "qq"])
        #expect(!mt.fillers.contains("mm"))
        for meaningful in ["mela", "allura", "jiġifieri", "taf", "eħe", "mhm"] {
            #expect(!mt.fillers.contains(meaningful))
        }
    }

    @Test("spoken symbols use a local rule without violating the shared field invariant")
    func localSymbolRule() {
        let mt = LanguagePack.maltese
        #expect(mt.symbols == nil)
        #expect(mt.rules.contains { $0.name == "render context-aware Maltese spoken symbols" })
        #expect(mt.spokenSymbolWords.contains("punt"))
        #expect(mt.spokenSymbolWords.contains("underscore"))
    }

    @Test("prompt guidance is complete but ships no unevaluated few-shot pairs")
    func promptPolicy() {
        let prompt = LanguagePack.maltese.prompt
        #expect(prompt.fillerExamples?.contains("mela") == true)
        #expect(prompt.capitalizationRule?.contains("Għ") == true)
        #expect(prompt.codeRendering?.contains("main punt py") == true)
        #expect(prompt.terminalGuidance?.contains("sing sing verbose") == true)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule?.contains("ħames, le sitt kopji") == true)
        #expect(prompt.addendum?.contains("12,345.67") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Maltese")
struct MalteseRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: category
            ),
            locale: "mt-MT"
        )
    }

    @Test("corpus-attested hesitation tokens are removed cleanly")
    func fillers() {
        #expect(clean("ee illum em se nibdew qq ix-xogħol") == "Illum se nibdew ix-xogħol.")
    }

    @Test("meaningful discourse markers and the mm unit are retained")
    func ambiguousFillersKept() {
        #expect(clean("mela allura nibdew ix-xogħol") == "Mela allura nibdew ix-xogħol.")
        #expect(clean("il-wisa' huwa 10 mm") == "Il-wisa’ huwa 10 mm.")
    }

    @Test("spoken punctuation renders and remains idempotent")
    func spokenPunctuation() {
        #expect(
            clean("għada niltaqgħu virgola jekk jogħġbok punt finali")
                == "Għada niltaqgħu, jekk jogħġbok."
        )
        #expect(clean("tajjeb, virgola nibdew") == "Tajjeb, nibdew.")
        #expect(clean("min ġej għada marka tal-mistoqsija") == "Min ġej għada?")
    }

    @Test("spoken quotations, parentheses, and line breaks survive shared whitespace cleanup")
    func spokenStructure() {
        #expect(
            clean("qal virgoletti miftuħa iva virgoletti magħluqa")
                == "Qal “iva”."
        )
        #expect(
            clean("ikkalkula parentesi miftuħa x virgola y parentesi magħluqa")
                == "Ikkalkula (x, y)."
        )
        #expect(clean("l-ewwel linja ġdida it-tieni") == "L-ewwel\nit-tieni.")
    }

    @Test("only reliably interrogative openers gain a question mark")
    func questionPolicy() {
        #expect(clean("min ġej għada") == "Min ġej għada?")
        #expect(clean("x’inhu l-pjan") == "X’inhu l-pjan?")
        #expect(clean("fejn mort ilbieraħ kien sabiħ") == "Fejn mort ilbieraħ kien sabiħ.")
    }

    @Test("Maltese thousands, decimals, currency, dates, and times keep their formats")
    func localeFormats() {
        #expect(
            clean("il-baġit huwa EUR 12,345.67")
                == "Il-baġit huwa EUR12,345.67."
        )
        #expect(clean("dan jiswa € 543.21") == "Dan jiswa €543.21.")
        #expect(
            clean("niltaqgħu fit-2 ta' lulju 2026")
                == "Niltaqgħu fit-2 ta’ Lulju 2026."
        )
        #expect(clean("niltaqgħu fl-14:30") == "Niltaqgħu fl-14:30.")
    }

    @Test("typographic apostrophes, balanced quotes, and article hyphens normalize in prose")
    func proseTypography() {
        #expect(clean("dan huwa l - eżempju ta' Mark") == "Dan huwa l-eżempju ta’ Mark.")
        #expect(clean(#"qal "għada niġi""#) == "Qal “għada niġi”.")
        #expect(clean("x ' taħseb dwar f ' April") == "X’taħseb dwar f’April.")
    }

    @Test("spoken file names and identifiers compact only around explicit triggers")
    func codeRendering() {
        #expect(clean("iftaħ main punt py") == "Iftaħ main.py")
        #expect(
            clean("issettja max underscore retries għal ħamsa")
                == "Issettja max_retries għal ħamsa."
        )
        #expect(clean("il-punt ewlieni huwa ċar") == "Il-punt ewlieni huwa ċar.")
    }

    @Test("terminal rendering is command-safe and protects filler-shaped tokens")
    func terminalCategory() {
        #expect(clean("git status sing sing short", category: .terminal) == "git status --short")
        #expect(clean("python main punt py", category: .terminal) == "python main.py")
        #expect(clean("printf em", category: .terminal) == "printf em")
        #expect(
            clean("cd tilde slash projects slash VoiceType", category: .terminal)
                == "cd ~/projects/VoiceType"
        )
    }

    @Test("numeric masking respects disabled punctuation and never leaks placeholders")
    func optionAndPlaceholderSafety() {
        let noPunctuation = CleanupOptions(
            removeFillers: true,
            addPunctuation: false,
            fixCapitalization: true
        )
        #expect(clean("il-valur huwa 1,234.50", options: noPunctuation)
            == "Il-valur huwa 1,234.50")
    }
}

@Suite("Cleanup polish — Maltese model output")
struct MaltesePolishTests {
    @Test("local orthographic rules repair model output too")
    func modelOutputParity() {
        let out = CleanupPolish.apply(
            "il-baġit huwa € 1,234.50",
            options: .default,
            locale: "mt-MT"
        )
        #expect(out == "Il-baġit huwa €1,234.50")

        let punctuation = CleanupPolish.apply(
            "għada virgola nibdew",
            options: .default,
            locale: "mt-MT"
        )
        #expect(punctuation == "Għada, nibdew")
    }

    @Test("Maltese assistant lead-ins are stripped conservatively")
    func localizedLeadIn() {
        let wrapped = "Żgur, hawn hu t-test imnaddaf: Għada nibdew."
        #expect(CleanupSanitizer.strip(wrapped, locale: "mt-MT") == "Għada nibdew.")
    }
}
