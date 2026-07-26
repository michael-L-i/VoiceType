import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Korean policy")
struct KoreanPackPolicyTests {
    @Test("only prolonged hesitation spellings are deterministic fillers")
    func conservativeFillers() {
        let ko = LanguagePack.korean
        #expect(ko.fillers == ["으음", "으으음", "어엄"])
        for meaningful in ["어", "음", "아", "그", "저", "뭐", "흠", "이제", "막"] {
            #expect(!ko.fillers.contains(meaningful))
        }
    }

    @Test("Korean remains a spaced, caseless pack without the reserved symbols field")
    func structure() {
        let ko = LanguagePack.korean
        #expect(ko.separatesWordsWithSpaces)
        #expect(!ko.usesFullWidthPunctuation)
        #expect(ko.preservesFullWidthMarks)
        #expect(ko.symbols == nil)
        #expect(ko.capitalizedStandalonePronoun == nil)
        #expect(ko.guardPolicy.minimumContentWords == 6)
    }

    @Test("question endings are distinctive rather than bare informal syllables")
    func questionPolicy() {
        let suffixes = LanguagePack.korean.questionSuffixParticles
        #expect(suffixes.contains("습니까"))
        #expect(suffixes.contains("까요"))
        #expect(!suffixes.contains("요"))
        #expect(!suffixes.contains("니"))
        #expect(!suffixes.contains("나"))
        #expect(LanguagePack.korean.questionPrefixWords.isEmpty)
    }

    @Test("prompt supplies every Korean guidance section without few-shot examples")
    func promptPolicy() {
        let prompt = LanguagePack.korean.prompt
        #expect(prompt.fillerExamples?.contains("그러니까") == true)
        #expect(prompt.capitalizationRule?.contains("no uppercase/lowercase") == true)
        #expect(prompt.codeRendering?.contains("메인 점 파이") == true)
        #expect(prompt.terminalGuidance?.contains("대시 대시 버보스") == true)
        #expect(prompt.codeEditorGuidance?.contains("Korean comments") == true)
        #expect(prompt.selfCorrectionRule?.contains("다섯 개, 아니 여섯 개") == true)
        #expect(prompt.addendum?.contains("2026년 7월 26일") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Korean")
struct KoreanRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(
                appBundleID: nil, appName: nil, category: category),
            locale: "ko-KR")
    }

    @Test("prolonged hesitation forms are removed")
    func fillers() {
        #expect(clean("으음 오늘 회의는 세 시입니다") == "오늘 회의는 세 시입니다.")
        #expect(clean("오늘은 어엄 회의를 먼저 합시다") == "오늘은 회의를 먼저 합시다.")
    }

    @Test("meaningful filler lookalikes and stance survive")
    func ambiguousFillersStay() {
        #expect(clean("음이 높고 흠이 하나 있다") == "음이 높고 흠이 하나 있다.")
        #expect(clean("그 계획은 이제 시작이다") == "그 계획은 이제 시작이다.")
    }

    @Test("documented spoken punctuation renders and is idempotent")
    func spokenPunctuation() {
        #expect(clean("안녕하세요 마침표") == "안녕하세요.")
        #expect(clean("첫째 쉼표 둘째 쉼표 셋째") == "첫째, 둘째, 셋째.")
        #expect(clean("정말입니까 물음표") == "정말입니까?")
        #expect(clean("좋습니다 느낌표") == "좋습니다!")
        #expect(clean("안녕하세요. 마침표") == "안녕하세요.")
    }

    @Test("quotation, bracket, colon, middle-dot and ellipsis names render")
    func namedMarks() {
        #expect(clean("따옴표 안녕하세요 따옴표 종료 라고 말했다")
            == "“안녕하세요” 라고 말했다.")
        #expect(clean("괄호 열기 참고 괄호 닫기") == "(참고)")
        #expect(clean("일시 쌍점 2026년 7월 26일") == "일시: 2026년 7월 26일.")
        #expect(clean("연구 가운뎃점 개발") == "연구·개발.")
        #expect(clean("아직 줄임표") == "아직……")
    }

    @Test("Apple line and paragraph commands survive whitespace normalization")
    func lineBreaks() {
        #expect(clean("첫째 새로운 줄 둘째") == "첫째\n둘째.")
        #expect(clean("첫 문단 새로운 단락 둘째 문단") == "첫 문단\n\n둘째 문단.")
    }

    @Test("distinctive interrogative endings gain a question mark")
    func questionEndings() {
        #expect(clean("회의를 지금 시작할까요") == "회의를 지금 시작할까요?")
        #expect(clean("이것이 새 버전입니까") == "이것이 새 버전입니까?")
        #expect(clean("결과를 확인했나요") == "결과를 확인했나요?")
    }

    @Test("ambiguous informal endings remain statements")
    func ambiguousQuestionEndings() {
        #expect(clean("우리는 내일 만나요") == "우리는 내일 만나요.")
        #expect(clean("이것은 중요한 문제지") == "이것은 중요한 문제지.")
    }

    @Test("numeric grouping, decimals, currency and percent remain compact")
    func numbers() {
        #expect(clean("예산은 ₩ 1,234,567 입니다") == "예산은 ₩1,234,567 입니다.")
        #expect(clean("성공률은 99.5 % 입니다") == "성공률은 99.5% 입니다.")
        #expect(clean("값은 1,234.5 입니다") == "값은 1,234.5 입니다.")
    }

    @Test("Korean date units and embedded English retain their written form")
    func datesAndEnglish() {
        #expect(clean("마감일은 2026년 7월 26일 입니다")
            == "마감일은 2026년 7월 26일 입니다.")
        #expect(clean("git 명령은 유용하다") == "git 명령은 유용하다.")
        #expect(clean("설명이다. swift 코드는 그대로 둔다")
            == "설명이다. swift 코드는 그대로 둔다.")
    }

    @Test("known file extensions and explicit identifier joiners render")
    func spokenCode() {
        #expect(clean("main 점 파이 파일을 열어 줘") == "main.py 파일을 열어 줘.")
        #expect(clean("config 언더스코어 dev 점 제이슨 파일")
            == "config_dev.json 파일.")
    }

    @Test("ordinary uses of 점 and 대시 are not rendered as code")
    func ambiguousSymbolsStay() {
        #expect(clean("이 점이 가장 중요하다") == "이 점이 가장 중요하다.")
        #expect(clean("백 점을 받았다") == "백 점을 받았다.")
        #expect(clean("선수가 결승선을 향해 대시했다") == "선수가 결승선을 향해 대시했다.")
    }

    @Test("anchored spoken email renders but Korean prose does not join")
    func email() {
        #expect(clean("주소는 michael 골뱅이 gmail 점 com")
            == "주소는 michael@gmail.com")
        #expect(clean("이 점 com 이야기는 이상하다")
            == "이 점 com 이야기는 이상하다.")
    }

    @Test("terminal category renders explicit flags and paths without prose punctuation")
    func terminalSymbols() {
        #expect(clean("git 대시 대시 verbose", category: .terminal) == "git --verbose")
        #expect(clean("틸드 슬래시 projects 슬래시 VoiceType", category: .terminal)
            == "~/projects/VoiceType")
        #expect(clean("echo 1,000", category: .terminal) == "echo 1,000")
    }

    @Test("an ordinary terminal command remains byte-for-byte safe")
    func terminalCommandSafe() {
        #expect(clean("git status", category: .terminal) == "git status")
    }

    @Test("always-correct typography still runs when optional lexical cleanup is off")
    func orthographyWithoutOptions() {
        let none = CleanupOptions(
            removeFillers: false,
            addPunctuation: false,
            fixCapitalization: false)
        #expect(clean("비용은 ₩ 1,000", options: none) == "비용은 ₩1,000")
        #expect(clean("으음 그대로", options: none) == "으음 그대로")
    }
}

@Suite("Cleanup polish — Korean model output")
struct KoreanPolishTests {
    @Test("model output receives the same spoken-name and code rendering")
    func symbolRepair() {
        let punctuation = CleanupPolish.apply(
            "안녕하세요 마침표", options: .default, locale: "ko-KR")
        let file = CleanupPolish.apply(
            "main 점 파이 파일", options: .default, locale: "ko-KR")
        #expect(punctuation == "안녕하세요.")
        #expect(file == "main.py 파일")
    }

    @Test("model output retains grouping commas and lowercase Latin openings")
    func numericAndCaseRepair() {
        let number = CleanupPolish.apply(
            "비용은 1,000원입니다.", options: .default, locale: "ko-KR")
        let casing = CleanupPolish.apply(
            "git 명령입니다.", options: .default, locale: "ko-KR")
        #expect(number == "비용은 1,000원입니다.")
        #expect(casing == "git 명령입니다.")
    }

    @Test("model output receives Korean line-break commands")
    func lineBreakRepair() {
        let out = CleanupPolish.apply(
            "첫째 새로운 줄 둘째.", options: .default, locale: "ko-KR")
        #expect(out == "첫째\n둘째.")
    }
}

@Suite("Cleanup prompt — Korean")
struct KoreanCleanupPromptTests {
    @Test("instructions are Korean-specific and contain no English fallback correction")
    func localizedGuidance() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "ko-KR")
        #expect(instructions.contains("Korean Hangul has no uppercase/lowercase"))
        #expect(instructions.contains("다섯 개, 아니 여섯 개"))
        #expect(instructions.contains("대시 대시 버보스"))
        #expect(instructions.contains("1,234.5"))
        #expect(!instructions.contains("five, no six copies"))
    }
}
