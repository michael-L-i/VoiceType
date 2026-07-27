import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Vietnamese policy")
struct VietnamesePackPolicyTests {
    @Test("only hesitation-length sounds are deterministic fillers")
    func fillerPolicy() {
        let vi = LanguagePack.vietnamese
        #expect(vi.fillers == ["ừm", "ờm", "ưm", "uhm", "hmm"])
        #expect(!vi.fillers.contains("ừ"))
        #expect(!vi.fillers.contains("ờ"))
        #expect(!vi.fillers.contains("à"))
        #expect(!vi.fillers.contains("thì"))
        #expect(!vi.fillers.contains("là"))
    }

    @Test("ambiguous Vietnamese question words do not drive blind punctuation")
    func questionPolicy() {
        let vi = LanguagePack.vietnamese
        #expect(vi.questionPrefixWords.isEmpty)
        #expect(vi.questionSuffixParticles.isEmpty)
    }

    @Test("the symbol pack field stays English-only while Vietnamese owns a rule")
    func symbolPolicy() {
        let vi = LanguagePack.vietnamese
        #expect(vi.symbols == nil)
        #expect(vi.rules.contains { $0.name == "render contextual Vietnamese code symbols" })
        #expect(SpokenSymbolVocabulary.vietnamese.dot == ["chấm"])
        #expect(SpokenSymbolVocabulary.vietnamese.fileExtensions.contains("py"))
        #expect(SpokenSymbolVocabulary.vietnamese.emailTLDs.contains("vn"))
    }

    @Test("prompt guidance is complete and ships no unvalidated few-shot text")
    func promptPolicy() {
        let prompt = LanguagePack.vietnamese.prompt
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

@Suite("Rule-based cleanup — Vietnamese")
struct VietnameseRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: category),
            locale: "vi-VN")
    }

    @Test("hesitation sounds are removed without leaving punctuation gaps")
    func fillers() {
        #expect(clean("ừm, chúng ta bắt đầu") == "Chúng ta bắt đầu.")
        #expect(clean("tôi ờm nghĩ phương án này tốt") == "Tôi nghĩ phương án này tốt.")
    }

    @Test("meaning-bearing lookalikes stay")
    func ambiguousFillersStay() {
        #expect(clean("ừ, tôi đồng ý") == "Ừ, tôi đồng ý.")
        #expect(clean("thì tôi sẽ làm") == "Thì tôi sẽ làm.")
        #expect(clean("đây là kết quả") == "Đây là kết quả.")
    }

    @Test("explicit spoken punctuation renders with Vietnamese spacing")
    func spokenPunctuation() {
        #expect(clean("xin chào dấu phẩy bạn khỏe không dấu hỏi")
            == "Xin chào, bạn khỏe không?")
        #expect(clean("lưu ý dấu hai chấm kiểm tra lại")
            == "Lưu ý: kiểm tra lại.")
        #expect(clean("xong dấu chấm than") == "Xong!")
        #expect(clean("còn nữa dấu ba chấm") == "Còn nữa…")
    }

    @Test("spoken punctuation is idempotent when ASR already emitted a mark")
    func spokenPunctuationIdempotent() {
        #expect(clean("tốt. dấu chấm") == "Tốt.")
        #expect(clean("đúng? dấu hỏi") == "Đúng?")
    }

    @Test("spoken quotes and brackets have no inner spaces")
    func pairedPunctuationSpacing() {
        #expect(clean("từ được chọn là mở ngoặc kép nhanh đóng ngoặc kép")
            == "Từ được chọn là “nhanh”.")
        #expect(clean("ghi mở ngoặc đơn bản nháp đóng ngoặc đơn")
            == "Ghi (bản nháp).")
        #expect(clean("chọn mở ngoặc vuông một dấu phẩy hai đóng ngoặc vuông")
            == "Chọn [một, hai].")
    }

    @Test("dictated line and paragraph breaks survive whitespace cleanup")
    func lineBreaks() {
        #expect(clean("mục một xuống dòng mục hai") == "Mục một\nMục hai.")
        #expect(clean("đoạn một xuống đoạn đoạn hai") == "Đoạn một\n\nĐoạn hai.")
    }

    @Test("compact decimal commas are never split as sentence commas")
    func decimalComma() {
        #expect(clean("nhiệt độ là 37,5 độ") == "Nhiệt độ là 37,5 độ.")
        #expect(clean("tỷ lệ tăng từ 1,25 lên 2,5 phần trăm")
            == "Tỷ lệ tăng từ 1,25 lên 2,5 phần trăm.")
    }

    @Test("localized percent and đồng sign spacing is deterministic")
    func localizedNumberAffixes() {
        #expect(clean("tỷ lệ là 75 %") == "Tỷ lệ là 75%.")
        #expect(clean("giá là 100.000 ₫") == "Giá là 100.000\u{00A0}₫.")
    }

    @Test("known file extensions, snake identifiers, and email addresses render")
    func contextualCodeSymbols() {
        #expect(clean("mở main chấm py") == "Mở main.py")
        #expect(clean("đặt max gạch dưới retries thành năm")
            == "Đặt max_retries thành năm.")
        #expect(clean("gửi tới an chấm nguyen a còng gmail chấm com")
            == "Gửi tới an.nguyen@gmail.com")
    }

    @Test("spoken parens render a compact function call")
    func functionCall() {
        #expect(clean("gọi print mở ngoặc x phẩy y đóng ngoặc")
            == "Gọi print(x, y)")
    }

    @Test("ordinary uses of chấm and gạch dưới are not corrupted")
    func proseSymbolGuards() {
        #expect(clean("tôi chấm bài vào buổi sáng") == "Tôi chấm bài vào buổi sáng.")
        #expect(clean("hãy gạch dưới từ quan trọng") == "Hãy gạch dưới từ quan trọng.")
    }

    @Test("ordinary ai and sao statements do not become questions")
    func ambiguousQuestionWords() {
        #expect(clean("ai cũng đồng ý") == "Ai cũng đồng ý.")
        #expect(clean("sao cũng được") == "Sao cũng được.")
    }

    @Test("embedded English and existing identifiers survive untouched")
    func embeddedTechnicalText() {
        #expect(clean("API parseRequest dùng config.json")
            == "API parseRequest dùng config.json")
    }

    @Test("terminal flags, paths, and operators render without prose damage")
    func terminalRendering() {
        #expect(clean("git commit gạch ngang m sửa lỗi đăng nhập", category: .terminal)
            == "git commit -m sửa lỗi đăng nhập")
        #expect(clean("npm run build gạch ngang gạch ngang verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd dấu ngã gạch chéo projects gạch chéo voice", category: .terminal)
            == "cd ~/projects/voice")
        #expect(clean("echo x dấu bằng y", category: .terminal) == "echo x = y")
    }

    @Test("prose punctuation commands sit out terminal dictation")
    func terminalPunctuationSafety() {
        #expect(clean("echo dấu chấm", category: .terminal) == "echo dấu chấm")
        #expect(clean("git status", category: .terminal) == "git status")
    }
}

@Suite("Cleanup polish — Vietnamese model output")
struct VietnamesePolishTests {
    @Test("pack punctuation rules repair model output too")
    func spokenPunctuation() {
        let out = CleanupPolish.apply(
            "xin chào dấu phẩy bạn",
            options: .default,
            locale: "vi-VN")
        #expect(out == "Xin chào, bạn")
    }

    @Test("decimal comma and code rendering survive model polish")
    func numericAndCodeRepair() {
        #expect(CleanupPolish.apply(
            "nhiệt độ 37,5 độ",
            options: .default,
            locale: "vi-VN") == "Nhiệt độ 37,5 độ")
        #expect(CleanupPolish.apply(
            "mở main chấm py",
            options: .default,
            locale: "vi-VN") == "Mở main.py")
    }

    @Test("Vietnamese conversational lead-ins are stripped")
    func localizedLeadIn() {
        #expect(CleanupSanitizer.strip(
            "Đây là văn bản đã làm sạch: xin chào.",
            pack: .vietnamese) == "xin chào.")
    }

    @Test("legitimate Vietnamese symbol rendering does not trip the faithfulness guard")
    func symbolRenderingIsFaithful() {
        #expect(!CleanupGuard.looksUnfaithful(
            raw: "từ được chọn là mở ngoặc kép nhanh đóng ngoặc kép",
            cleaned: "Từ được chọn là “nhanh”.",
            locale: "vi-VN"))
        #expect(!CleanupGuard.looksUnfaithful(
            raw: "cd dấu ngã gạch chéo projects gạch chéo voice",
            cleaned: "cd ~/projects/voice",
            locale: "vi-VN"))
    }
}
