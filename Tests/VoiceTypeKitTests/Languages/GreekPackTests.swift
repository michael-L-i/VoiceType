import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Greek policy")
struct GreekPackPolicyTests {
    @Test("uses the preferred U+003B Greek question mark, not compatibility U+037E")
    func questionMarkCodePoint() {
        let mark = LanguagePack.greek.questionMark
        #expect(mark == ";")
        #expect(mark.unicodeScalars.map(\.value) == [0x003B])
        // Canonical Unicode equality intentionally treats U+003B and U+037E
        // as equal, so scalar inspection above is the code-point assertion.
        #expect(mark.unicodeScalars.map(\.value) != [0x037E])
        #expect(mark.unicodeScalars.map(\.value) != [0x0387])
    }

    @Test("removes only prolonged hesitation tokens")
    func conservativeFillers() {
        let el = LanguagePack.greek
        #expect(el.fillers.contains("εεε"))
        #expect(el.fillers.contains("εμμ"))
        #expect(!el.fillers.contains("ε"))
        #expect(!el.fillers.contains("εμ"))
        #expect(!el.fillers.contains("εε"))
        #expect(!el.fillers.contains("λοιπόν"))
        #expect(!el.fillers.contains("δηλαδή"))
        #expect(!el.fillers.contains("βασικά"))
    }

    @Test("keeps pack symbols nil and invokes its vocabulary from local rules")
    func symbolsStayLocal() {
        let el = LanguagePack.greek
        #expect(el.symbols == nil)
        #expect(el.spokenSymbolWords.contains("κάτω_παύλα"))
        #expect(el.spokenSymbolWords.contains("παπάκι"))
        #expect(el.capitalizedStandalonePronoun == nil)
    }

    @Test("ships complete Greek prompt guidance without unvalidated few-shot examples")
    func promptGuidance() {
        let prompt = LanguagePack.greek.prompt
        #expect(prompt.fillerExamples?.contains("εμμ") == true)
        #expect(prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(prompt.codeRendering?.contains("main.py") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("monotonic Greek") == true)
        #expect(prompt.selfCorrectionRule?.contains("την Τετάρτη") == true)
        #expect(prompt.addendum?.contains("U+003B") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Greek")
struct GreekRuleCleanupTests {
    private func clean(
        _ text: String,
        options: CleanupOptions = .default,
        category: AppCategory = .general
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: category),
            locale: "el-GR")
    }

    @Test("prolonged fillers are removed but ΕΕ and meaningful discourse words survive")
    func fillers() {
        #expect(clean("εμμ νομίζω ότι είναι έτοιμο") == "Νομίζω ότι είναι έτοιμο.")
        #expect(clean("η ΕΕ, λοιπόν, αποφάσισε") == "Η ΕΕ, λοιπόν, αποφάσισε.")
        #expect(clean("δηλαδή αυτό εννοείς") == "Δηλαδή αυτό εννοείς.")
    }

    @Test("the remove-fillers option still controls Greek fillers")
    func fillerOption() {
        let keep = CleanupOptions(
            removeFillers: false,
            addPunctuation: true,
            fixCapitalization: true)
        #expect(clean("εμμ νομίζω ότι είναι έτοιμο", options: keep)
            == "Εμμ νομίζω ότι είναι έτοιμο.")
    }

    @Test("explicit spoken punctuation renders and is idempotent")
    func spokenPunctuation() {
        #expect(clean("είναι έτοιμο βάλε τελεία") == "Είναι έτοιμο.")
        #expect(clean("είναι έτοιμο. βάλε τελεία") == "Είναι έτοιμο.")
        #expect(clean("πού είσαι ερωτηματικό") == "Πού είσαι;")
        #expect(clean("πρόσεχε θαυμαστικό") == "Πρόσεχε!")
    }

    @Test("spoken line and paragraph breaks survive the shared whitespace pass")
    func spokenBreaks() {
        #expect(clean("πρώτη γραμμή νέα γραμμή δεύτερη γραμμή")
            == "Πρώτη γραμμή\nΔεύτερη γραμμή.")
        #expect(clean("πρώτη παράγραφος νέα παράγραφος δεύτερη παράγραφος")
            == "Πρώτη παράγραφος\n\nΔεύτερη παράγραφος.")
    }

    @Test("spoken quotations become tightly spaced Greek guillemets")
    func spokenQuotes() {
        #expect(clean("είπε άνοιγμα εισαγωγικών ναι κλείσιμο εισαγωγικών")
            == "Είπε «ναι».")
    }

    @Test("direct question prefixes gain U+003B and subsequent sentences capitalize")
    func questionHeuristic() {
        #expect(clean("ποιος έρχεται") == "Ποιος έρχεται;")
        #expect(clean("πού είσαι; τι κάνεις") == "Πού είσαι; Τι κάνεις;")
        #expect(clean("γιατί δεν είχα χρόνο") == "Γιατί δεν είχα χρόνο.")
    }

    @Test("ASCII and compatibility question marks normalize only after Greek prose")
    func questionMarkNormalization() {
        #expect(clean("πού είσαι?") == "Πού είσαι;")
        #expect(clean("πού είσαι\u{037E}") == "Πού είσαι;")
        #expect(clean("δες https://example.com?q=1") == "Δες https://example.com?q=1")
    }

    @Test("Greek decimal commas and thousands punctuation stay compact")
    func numbers() {
        #expect(clean("η τιμή είναι 3,14") == "Η τιμή είναι 3,14.")
        #expect(clean("το ποσό είναι 1.234,56 ευρώ") == "Το ποσό είναι 1.234,56 ευρώ.")
        #expect(clean("οι επιλογές είναι 1,2,3") == "Οι επιλογές είναι 1, 2, 3.")
        #expect(clean("η έκδοση είναι 3.14") == "Η έκδοση είναι 3.14")
    }

    @Test("elision uses the Greek right apostrophe followed by a space")
    func apostrophe() {
        #expect(clean("γι'αυτό συμφωνώ") == "Γι’ αυτό συμφωνώ.")
        #expect(clean("απ΄ό,τι θυμάμαι") == "Απ’ ό,τι θυμάμαι.")
    }

    @Test("abbreviation periods do not trigger false sentence capitalization")
    func abbreviations() {
        #expect(clean("χρησιμοποιούμε Python, Swift κ.λπ. και συνεχίζουμε")
            == "Χρησιμοποιούμε Python, Swift κ.λπ. και συνεχίζουμε.")
        #expect(clean("φέρτε χαρτί, μολύβι κ.λπ.")
            == "Φέρτε χαρτί, μολύβι κ.λπ.")
    }

    @Test("ano teleia normalizes to preferred U+00B7 with Greek spacing")
    func anoTeleia() {
        let out = clean("ήθελε να φύγει \u{0387} δεν μπορούσε")
        #expect(out == "Ήθελε να φύγει· δεν μπορούσε.")
        #expect(out.unicodeScalars.contains { $0.value == 0x00B7 })
        #expect(!out.unicodeScalars.contains { $0.value == 0x0387 })
    }

    @Test("spoken file names, identifiers, calls, and email addresses render compactly")
    func spokenSymbols() {
        #expect(clean("άνοιξε το main τελεία py") == "Άνοιξε το main.py")
        #expect(clean("όρισε max κάτω παύλα retries σε πέντε")
            == "Όρισε max_retries σε πέντε.")
        #expect(clean("κάλεσε print άνοιγμα παρένθεση x κόμμα y κλείσιμο παρένθεση")
            == "Κάλεσε print(x, y)")
        #expect(clean("στείλε στο john τελεία smith παπάκι gmail τελεία com")
            == "Στείλε στο john.smith@gmail.com")
    }

    @Test("ordinary symbol-like Greek nouns and embedded identifiers remain prose")
    func proseAndIdentifierGuards() {
        #expect(clean("η τελεία δείχνει το τέλος") == "Η τελεία δείχνει το τέλος.")
        #expect(clean("η κάτω παύλα είναι χρήσιμη") == "Η κάτω παύλα είναι χρήσιμη.")
        #expect(clean("το VoiceType ανοίγει το config.json") == "Το VoiceType ανοίγει το config.json")
    }

    @Test("terminal rendering is opt-in only for command-safe flags and paths")
    func terminal() {
        #expect(clean("git commit παύλα m fix", category: .terminal)
            == "git commit -m fix")
        #expect(clean("cat περισπωμένη κάθετος projects κάθετος notes.txt", category: .terminal)
            == "cat ~/projects/notes.txt")
        #expect(clean("echo πού είσαι;", category: .terminal) == "echo πού είσαι;")
    }
}

@Suite("Cleanup polish — Greek model output")
struct GreekPolishTests {
    @Test("model punctuation drift and mechanical Greek orthography are repaired")
    func punctuationAndNumbers() {
        #expect(CleanupPolish.apply(
            "πού είσαι?",
            options: .default,
            locale: "el-GR") == "Πού είσαι;")
        #expect(CleanupPolish.apply(
            "η τιμή είναι 3,14",
            options: .default,
            locale: "el-GR") == "Η τιμή είναι 3,14")
        #expect(CleanupPolish.apply(
            "χρησιμοποιούμε π.χ. Python",
            options: .default,
            locale: "el-GR") == "Χρησιμοποιούμε π.χ. Python")
    }

    @Test("Greek sanitizer strips a model-authored lead-in")
    func sanitizerLeadIn() {
        #expect(CleanupSanitizer.strip(
            "Βεβαίως, ορίστε το καθαρισμένο κείμενο: Αυτό είναι το κείμενο.",
            locale: "el-GR") == "Αυτό είναι το κείμενο.")
    }
}
