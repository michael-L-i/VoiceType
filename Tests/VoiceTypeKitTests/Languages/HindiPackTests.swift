import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Hindi policy")
struct HindiPackPolicyTests {
    @Test("Hindi declares danda, caseless writing, and language-owned symbols")
    func corePolicy() {
        let hi = LanguagePack.hindi
        #expect(hi.terminalPeriod == "।")
        #expect(hi.terminalMarks.contains("।"))
        #expect(hi.terminalMarks.contains("॥"))
        #expect(hi.separatesWordsWithSpaces)
        #expect(!hi.usesFullWidthPunctuation)
        #expect(hi.capitalizedStandalonePronoun == nil)
        #expect(hi.casingLocaleIdentifier == nil)
        #expect(hi.symbols == nil)
    }

    @Test("only non-lexical pauses are deterministic fillers")
    func fillerPolicy() {
        let hi = LanguagePack.hindi
        #expect(hi.fillers.contains("उमम्"))
        #expect(hi.fillers.contains("उह"))
        for meaningful in ["मतलब", "यानी", "तो", "अच्छा", "वो", "हाँ", "हम्म", "नहीं"] {
            #expect(!hi.fillers.contains(meaningful))
        }
    }

    @Test("prompt guidance is Hindi-specific and ships no unmeasured few-shot examples")
    func promptPolicy() {
        let prompt = LanguagePack.hindi.prompt
        #expect(prompt.fillerExamples?.contains("मतलब") == true)
        #expect(prompt.capitalizationRule?.contains("no uppercase or lowercase") == true)
        #expect(prompt.codeRendering?.contains("main डॉट पाई") == true)
        #expect(prompt.terminalGuidance?.contains("डैश") == true)
        #expect(prompt.codeEditorGuidance?.contains("code-switching") == true)
        #expect(prompt.selfCorrectionRule?.contains("गुरुवार") == true)
        #expect(prompt.addendum?.contains("12,34,567.89") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Hindi")
struct HindiRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "hi-IN")
    }

    @Test("pure filled pauses are removed at word boundaries")
    func fillers() {
        #expect(clean("उमम् आज मौसम अच्छा है") == "आज मौसम अच्छा है।")
        #expect(clean("हम उह कल मिलेंगे") == "हम कल मिलेंगे।")
    }

    @Test("meaningful discourse-marker lookalikes survive deterministically")
    func ambiguousFillersKept() {
        let out = clean("मतलब यह है कि वो अच्छा विकल्प नहीं है")
        #expect(out == "मतलब यह है कि वो अच्छा विकल्प नहीं है।")
    }

    @Test("established spoken punctuation names render with Hindi spacing")
    func spokenPunctuation() {
        #expect(clean("आज मौसम अच्छा है पूर्ण विराम") == "आज मौसम अच्छा है।")
        #expect(clean("सेब अल्पविराम केला अल्पविराम आम") == "सेब, केला, आम।")
        #expect(clean("तुम कब आओगे प्रश्न चिह्न") == "तुम कब आओगे?")
        #expect(clean("बहुत बढ़िया विस्मयसूचक चिह्न") == "बहुत बढ़िया!")
    }

    @Test("spoken danda is idempotent when ASR already emitted it")
    func spokenPunctuationIdempotent() {
        #expect(clean("आज मौसम अच्छा है। पूर्ण विराम") == "आज मौसम अच्छा है।")
    }

    @Test("dictated line and paragraph breaks survive shared whitespace cleanup")
    func dictatedBreaks() {
        #expect(clean("पहली पंक्ति नई पंक्ति दूसरी पंक्ति")
            == "पहली पंक्ति\nदूसरी पंक्ति।")
        #expect(clean("पहला अनुच्छेद नया अनुच्छेद दूसरा अनुच्छेद")
            == "पहला अनुच्छेद\n\nदूसरा अनुच्छेद।")
    }

    @Test("direct Hindi question openers and final क्या gain a question mark")
    func questions() {
        #expect(clean("कहाँ जा रहे हो") == "कहाँ जा रहे हो?")
        #expect(clean("क्या तुम तैयार हो") == "क्या तुम तैयार हो?")
        #expect(clean("तुम तैयार हो क्या") == "तुम तैयार हो क्या?")
    }

    @Test("ambiguous tag particles never force a question")
    func ambiguousQuestionParticles() {
        #expect(clean("यह काम कर दो ना") == "यह काम कर दो ना।")
        #expect(clean("मैं नहीं जाऊँगा") == "मैं नहीं जाऊँगा।")
    }

    @Test("plain Hindi statements gain danda and clear ASCII sentence periods normalize")
    func danda() {
        #expect(clean("यह ठीक है") == "यह ठीक है।")
        #expect(clean("यह ठीक है.") == "यह ठीक है।")
        #expect(clean("पहला वाक्य. दूसरा वाक्य") == "पहला वाक्य। दूसरा वाक्य।")
    }

    @Test("common dotted abbreviations are not mistaken for sentence periods")
    func abbreviations() {
        #expect(clean("डॉ. शर्मा आज आए") == "डॉ. शर्मा आज आए।")
        #expect(clean("प्रो. वर्मा ने पढ़ाया") == "प्रो. वर्मा ने पढ़ाया।")
        #expect(clean("एम. ए. की डिग्री मिली") == "एम. ए. की डिग्री मिली।")
        #expect(clean("रा.कृ. शर्मा आए") == "रा.कृ. शर्मा आए।")
        #expect(clean("रा॰कृ॰ शर्मा आए") == "रा॰कृ॰ शर्मा आए।")
    }

    @Test("balanced Hindi quotes become typographic and lose inner padding")
    func quotationMarks() {
        #expect(clean(#"उसने कहा, " मैं तैयार हूँ " ."#)
            == "उसने कहा, “मैं तैयार हूँ”।")
        #expect(clean("इसे 'महत्वपूर्ण' मानो")
            == "इसे ‘महत्वपूर्ण’ मानो।")
        #expect(clean(#"कोड "main.py" ही रखो"#)
            == #"कोड "main.py" ही रखो।"#)
    }

    @Test("parentheses have no inner padding")
    func parentheses() {
        #expect(clean("नियम ( महत्वपूर्ण ) है") == "नियम (महत्वपूर्ण) है।")
    }

    @Test("colon spacing is repaired only in Devanagari prose")
    func colonSpacing() {
        #expect(clean("सूची:सेब और आम") == "सूची: सेब और आम।")
        #expect(clean("समय 09:30 है") == "समय 09:30 है।")
    }

    @Test("Indian grouping and decimals survive the shared comma pass")
    func numericSeparators() {
        #expect(clean("कुल 12,34,567.89 रुपये हैं") == "कुल 12,34,567.89 रुपये हैं।")
        #expect(clean("तारीख 26/07/2026 है") == "तारीख 26/07/2026 है।")
        #expect(clean("संस्करण v1.2 ठीक है") == "संस्करण v1.2 ठीक है।")
    }

    @Test("rupee and percent symbols use Hindi locale spacing")
    func currencyAndPercent() {
        #expect(clean("राशि ₹ 12,34,567 है और वृद्धि 28 % है")
            == "राशि ₹12,34,567 है और वृद्धि 28% है।")
    }

    @Test("guarded spoken dot renders known file extensions only")
    func fileNames() {
        #expect(clean("main डॉट पाई खोलो") == "main.py खोलो।")
        #expect(clean("config डॉट जेसन भेजो") == "config.json भेजो।")
        #expect(clean("लाल डॉट लगाओ") == "लाल डॉट लगाओ।")
    }

    @Test("guarded underscore and parentheses render compact code")
    func identifiersAndParens() {
        #expect(clean("max अंडरस्कोर retries बदलो") == "max_retries बदलो।")
        #expect(clean("print खुला कोष्ठक x कॉमा y बंद कोष्ठक")
            == "print(x, y)")
        #expect(clean("print खुला कोष्ठक x कॉमा y बंद कोष्ठक चलाओ")
            == "print(x, y) चलाओ।")
    }

    @Test("leading embedded Latin tokens keep their exact case")
    func embeddedLatinCase() {
        #expect(clean("git एक कमांड है") == "git एक कमांड है।")
        #expect(clean("main.py यहाँ है") == "main.py यहाँ है।")
    }

    @Test("terminal commands stay unpunctuated and render Hindi flags and paths")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git commit डैश m संदेश", category: .terminal)
            == "git commit -m संदेश")
        #expect(clean("npm run build डैश डैश verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd टिल्ड स्लैश projects स्लैश VoiceType", category: .terminal)
            == "cd ~/projects/VoiceType")
    }

    @Test("Hindi orthographic rules are idempotent")
    func idempotence() {
        let once = clean("राशि ₹ 12,34,567.89 है पूर्ण विराम")
        #expect(clean(once) == once)
    }
}

@Suite("Cleanup polish — Hindi model output")
struct HindiPolishTests {
    @Test("model punctuation drift is repaired to danda")
    func dandaRepair() {
        #expect(CleanupPolish.apply("यह ठीक है.", options: .default, locale: "hi-IN")
            == "यह ठीक है।")
    }

    @Test("model output receives quote, grouping, and technical-symbol repairs")
    func sharedRepairs() {
        #expect(CleanupPolish.apply(#"" नमस्ते " राशि ₹ 12,34,567 है."#,
                                    options: .default, locale: "hi-IN")
            == "“नमस्ते” राशि ₹12,34,567 है।")
        #expect(CleanupPolish.apply("main डॉट पाई खोलो।",
                                    options: .default, locale: "hi-IN")
            == "main.py खोलो।")
    }

    @Test("model polish does not capitalize an embedded leading command")
    func latinCase() {
        #expect(CleanupPolish.apply("git एक कमांड है।",
                                    options: .default, locale: "hi-IN")
            == "git एक कमांड है।")
    }
}

@Suite("Cleanup sanitizer and guard — Hindi")
struct HindiSafetyTests {
    @Test("Hindi assistant lead-ins are stripped without touching ordinary prose")
    func leadIn() {
        #expect(CleanupSanitizer.strip(
            "ज़रूर, यहाँ साफ़ किया हुआ टेक्स्ट है: आज मौसम अच्छा है।",
            locale: "hi-IN") == "आज मौसम अच्छा है।")
        #expect(CleanupSanitizer.strip(
            "यह रहा मेरा प्रस्ताव: आज ही शुरू करें।",
            locale: "hi-IN") == "यह रहा मेरा प्रस्ताव: आज ही शुरू करें।")
    }

    @Test("Hindi symbol names are discounted by the faithfulness guard")
    func guardSymbolWords() {
        let raw = "main डॉट पाई और max अंडरस्कोर retries को आज बदलना है"
        #expect(!CleanupGuard.looksUnfaithful(
            raw: raw,
            cleaned: "main.py और max_retries को आज बदलना है।",
            locale: "hi-IN"))
    }
}
