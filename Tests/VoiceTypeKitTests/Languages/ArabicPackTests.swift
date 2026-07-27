import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Arabic policy")
struct ArabicPackPolicyTests {
    @Test("uses the exact Arabic punctuation code points")
    func punctuationCodePoints() {
        let ar = LanguagePack.arabic
        #expect(ar.questionMark.unicodeScalars.map(\.value) == [0x061F])
        #expect(ar.spokenPunctuation["فاصلة منقوطة"]?.unicodeScalars.map(\.value) == [0x061B])
        #expect(ar.terminalMarks.contains("\u{060C}"))
        #expect(ar.terminalMarks.contains("\u{061B}"))
        #expect(ar.terminalMarks.contains("\u{061F}"))
    }

    @Test("has no casing policy and does not set the pack symbol field")
    func casingAndSymbolsPolicy() {
        let ar = LanguagePack.arabic
        #expect(ar.capitalizedStandalonePronoun == nil)
        #expect(ar.casingLocaleIdentifier == nil)
        #expect(ar.symbols == nil)
    }

    @Test("only non-lexical elongations are deterministic fillers")
    func fillerPolicy() {
        let ar = LanguagePack.arabic
        #expect(ar.fillers.contains("إمم"))
        #expect(ar.fillers.contains("ممم"))
        #expect(!ar.fillers.contains("أمم"))
        #expect(!ar.fillers.contains("همم"))
        #expect(!ar.fillers.contains("آه"))
        #expect(!ar.fillers.contains("يعني"))
        #expect(!ar.fillers.contains("طيب"))
    }

    @Test("bare ambiguous punctuation words are excluded")
    func punctuationAmbiguityPolicy() {
        let ar = LanguagePack.arabic
        #expect(ar.spokenPunctuation["نقطة"] == nil)
        #expect(ar.spokenPunctuation["فاصلة"] == nil)
        #expect(ar.spokenPunctuation["شرطة"] == nil)
        #expect(ar.spokenPunctuation["علامة استفهام"] == "؟")
    }

    @Test("prompt guidance covers every Arabic-specific surface without few-shot leakage")
    func promptPolicy() {
        let prompt = LanguagePack.arabic.prompt
        #expect(prompt.fillerExamples?.contains("يعني") == true)
        #expect(prompt.capitalizationRule?.contains("no uppercase or lowercase") == true)
        #expect(prompt.codeRendering?.contains("main.py") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("Latin script") == true)
        #expect(prompt.selfCorrectionRule?.contains("لا، قصدي") == true)
        #expect(prompt.addendum?.contains("U+061F") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Arabic")
struct ArabicRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "ar-SA")
    }

    @Test("pure hesitation elongations are removed without orphan commas")
    func fillers() {
        #expect(clean("إمم، سنبدأ الآن") == "سنبدأ الآن.")
        #expect(clean("أعتقد، ممم، أن الخطة جاهزة") == "أعتقد، أن الخطة جاهزة.")
    }

    @Test("meaningful lookalike fillers are retained")
    func ambiguousFillers() {
        #expect(clean("أمم كثيرة لها تاريخ عريق") == "أمم كثيرة لها تاريخ عريق.")
        #expect(clean("هذه النقطة يعني أن الخطة نجحت") == "هذه النقطة يعني أن الخطة نجحت.")
        #expect(clean("آه يؤلمني رأسي") == "آه يؤلمني رأسي.")
    }

    @Test("explicit spoken punctuation renders Arabic marks")
    func spokenPunctuation() {
        #expect(clean("هل انتهيت علامة استفهام") == "هل انتهيت؟")
        #expect(clean("تأخرنا فاصلة منقوطة الطريق مزدحم") == "تأخرنا؛ الطريق مزدحم.")
        #expect(clean("تحذير علامة تعجب") == "تحذير!")
    }

    @Test("spoken punctuation is idempotent when ASR already emitted the mark")
    func spokenPunctuationIdempotent() {
        #expect(clean("هل انتهيت؟ علامة استفهام") == "هل انتهيت؟")
    }

    @Test("documented spoken line break survives shared whitespace cleanup")
    func spokenLineBreak() {
        #expect(clean("السطر الأول أول السطر السطر الثاني") == "السطر الأول\nالسطر الثاني.")
    }

    @Test("ASCII lookalikes become Arabic punctuation only in Arabic prose")
    func punctuationShapes() {
        #expect(clean("مرحبًا ,كيف حالك ?") == "مرحبًا، كيف حالك؟")
        #expect(clean("تأخرنا ;لأن الطريق مزدحم") == "تأخرنا؛ لأن الطريق مزدحم.")
    }

    @Test("Arabic punctuation touches the preceding word and has one following space")
    func punctuationSpacing() {
        #expect(clean("الأول ،  الثاني؛الثالث ؟") == "الأول، الثاني؛ الثالث؟")
    }

    @Test("strong initial interrogatives gain U+061F")
    func questions() {
        #expect(clean("هل انتهى الاجتماع") == "هل انتهى الاجتماع؟")
        #expect(clean("أين ملف التقرير") == "أين ملف التقرير؟")
        #expect(clean("كيف نصل إلى المحطة") == "كيف نصل إلى المحطة؟")
    }

    @Test("ambiguous initial ما and من do not force question punctuation")
    func ambiguousQuestionWords() {
        #expect(clean("ما زال العمل مستمرًا") == "ما زال العمل مستمرًا.")
        #expect(clean("من الأفضل تأجيل الموعد") == "من الأفضل تأجيل الموعد.")
    }

    @Test("plain Arabic statements gain the shared full stop")
    func terminalPeriod() {
        #expect(clean("الخطة جاهزة") == "الخطة جاهزة.")
    }

    @Test("known file extensions render while ordinary نقطة remains prose")
    func guardedDot() {
        #expect(clean("افتح main نقطة py") == "افتح main.py")
        #expect(clean("هذه نقطة مهمة") == "هذه نقطة مهمة.")
    }

    @Test("explicit underscore phrase joins an identifier")
    func identifier() {
        #expect(clean("سمه user شرطة سفلية id") == "سمه user_id")
    }

    @Test("embedded Latin identifiers preserve script, punctuation, and case")
    func embeddedLatin() {
        #expect(clean("main يعمل هنا") == "main يعمل هنا.")
        #expect(clean("أرسل APIClient و main.py غدًا") == "أرسل APIClient و main.py غدًا.")
        #expect(clean("استخدم foo?bar داخل المثال") == "استخدم foo?bar داخل المثال.")
    }

    @Test("European and Arabic-Indic number systems remain exactly as supplied")
    func numbers() {
        #expect(clean("القيمة 1,234.50 ريال") == "القيمة 1,234.50 ريال.")
        #expect(clean("القيمة ١٬٢٣٤٫٥٠ ريال") == "القيمة ١٬٢٣٤٫٥٠ ريال.")
        #expect(clean("النسبة ١،٥ بالمئة") == "النسبة ١،٥ بالمئة.")
    }

    @Test("terminal flags and paths render without prose punctuation")
    func terminalSymbols() {
        #expect(clean("git status داش داش short", category: .terminal) == "git status --short")
        #expect(clean("cd تيلدا سلاش projects سلاش VoiceType", category: .terminal)
                == "cd ~/projects/VoiceType")
        #expect(clean("python main نقطة py", category: .terminal) == "python main.py")
    }

    @Test("terminal mode does not apply prose punctuation rules")
    func terminalSafety() {
        // The shared engine still tidies ASCII comma spacing in terminals; the
        // Arabic rule must sit out and not change its shape to U+060C.
        #expect(clean("echo مرحبا ,العالم", category: .terminal) == "echo مرحبا, العالم")
        #expect(clean("git status", category: .terminal) == "git status")
    }

    @Test("cleanup inserts no bidirectional control characters")
    func noBidiControls() {
        let output = clean("أرسل main.py إلى الفريق")
        let forbidden = Set<UInt32>([
            0x061C, 0x200E, 0x200F, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
            0x2066, 0x2067, 0x2068, 0x2069,
        ])
        #expect(output.unicodeScalars.allSatisfy { !forbidden.contains($0.value) })
    }
}

@Suite("Cleanup polish — Arabic model output")
struct ArabicPolishTests {
    @Test("model ASCII punctuation drift is repaired and spaced")
    func punctuationRepair() {
        let out = CleanupPolish.apply(
            "مرحبًا,كيف حالك?",
            options: .default,
            locale: "ar-EG")
        #expect(out == "مرحبًا، كيف حالك؟")
    }

    @Test("explicit punctuation words left by the model are rendered")
    func spokenPunctuationRepair() {
        let out = CleanupPolish.apply(
            "هل انتهيت علامة استفهام",
            options: .default,
            locale: "ar-EG")
        #expect(out == "هل انتهيت؟")
    }

    @Test("model cleanup cannot capitalize a leading Latin identifier")
    func latinCaseRepair() {
        let out = CleanupPolish.apply(
            "main يعمل هنا.",
            options: .default,
            locale: "ar-EG")
        #expect(out == "main يعمل هنا.")
    }
}
