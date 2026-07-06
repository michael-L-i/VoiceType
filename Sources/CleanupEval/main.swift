import Foundation
import VoiceTypeKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Dev-only eval harness for the cleanup prompt.
///
/// Mirrors `FoundationModelsCleanupEngine` exactly — same instructions, same
/// temperature, same sanitizer, same length guard — so what passes here is
/// what ships. For each case it prints a JSON line with the model output and
/// deterministic faithfulness metrics; a human (or agent) judges the fuzzy
/// rest.
///
/// Usage: swift run CleanupEval Scripts/cleanup-eval/cases.json [--id <caseID>] [--runs N]

struct EvalCase: Codable {
    let id: String
    let transcript: String
    /// AppCategory raw value; defaults to general.
    var category: String?
    /// Exact expected output (for deterministic code/terminal cases).
    var exact: String?
    /// Substrings that must appear in the cleaned output.
    var mustContain: [String]?
    /// Substrings that must NOT appear in the cleaned output.
    var mustNotContain: [String]?
    /// Free-form note about what this case probes.
    var note: String?
}

struct EvalResult: Codable {
    let id: String
    let run: Int
    let category: String
    let transcript: String
    let cleaned: String
    let ok: Bool?          // pass/fail of the declared expectations (nil = judge manually)
    let failures: [String] // which expectations failed
    let guardTripped: Bool // production guard would have fallen back to rule-based
    let retention: Double  // cleaned words / raw content-ish words
    let orderScore: Double // LCS(raw words, cleaned words) / cleaned words — 1.0 = no reordering
    let addedWords: [String] // cleaned content words absent from the raw transcript
    let latencySeconds: Double
}

// MARK: - Deterministic metrics

func words(_ text: String) -> [String] {
    text.lowercased()
        .replacingOccurrences(of: "[^a-z0-9' ]", with: " ", options: .regularExpression)
        .split(separator: " ")
        .map(String.init)
        .filter { !$0.isEmpty }
}

/// Longest common subsequence length over word arrays. If every cleaned word
/// appears in the raw transcript in the same relative order, LCS == cleaned
/// count and the order score is 1.0.
func lcs(_ a: [String], _ b: [String]) -> Int {
    guard !a.isEmpty, !b.isEmpty else { return 0 }
    var dp = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
    for i in 1...a.count {
        for j in 1...b.count {
            dp[i][j] = a[i-1] == b[j-1] ? dp[i-1][j-1] + 1 : max(dp[i-1][j], dp[i][j-1])
        }
    }
    return dp[a.count][b.count]
}

/// Words in `cleaned` that never occur in `raw` — invented content, modulo
/// legitimate joins (get_user_data, app.py) which tokenize apart again.
func newWords(raw: [String], cleaned: [String]) -> [String] {
    let rawSet = Set(raw)
    // Also allow fragments of joined identifiers: split cleaned words on _ . -
    return Array(Set(cleaned.filter { word in
        if rawSet.contains(word) { return false }
        let parts = word.split(whereSeparator: { "._-/~".contains($0) }).map(String.init)
        return !parts.allSatisfy { rawSet.contains($0) || $0.count <= 2 }
    })).sorted()
}

// MARK: - Main

@main
struct CleanupEval {
    static func main() async {
        var args = Array(CommandLine.arguments.dropFirst())
        var runs = 1
        var onlyID: String?
        if let i = args.firstIndex(of: "--runs"), i + 1 < args.count {
            runs = Int(args[i + 1]) ?? 1
            args.removeSubrange(i...(i + 1))
        }
        if let i = args.firstIndex(of: "--id"), i + 1 < args.count {
            onlyID = args[i + 1]
            args.removeSubrange(i...(i + 1))
        }
        guard let path = args.first else {
            FileHandle.standardError.write(Data("usage: CleanupEval <cases.json> [--id <caseID>] [--runs N]\n".utf8))
            exit(2)
        }

        #if canImport(FoundationModels)
        guard case .available = SystemLanguageModel.default.availability else {
            FileHandle.standardError.write(Data("FATAL: on-device model unavailable: \(SystemLanguageModel.default.availability)\n".utf8))
            exit(1)
        }

        let cases: [EvalCase]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            cases = try JSONDecoder().decode([EvalCase].self, from: data)
        } catch {
            FileHandle.standardError.write(Data("FATAL: could not load cases: \(error)\n".utf8))
            exit(1)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        var passed = 0, failed = 0, manual = 0

        for c in cases where onlyID == nil || c.id == onlyID {
            let category = AppCategory(rawValue: c.category ?? "general") ?? .general
            let context = CleanupContext(category: category)
            let instructions = CleanupPrompt.instructions(for: .default, context: context)

            for run in 1...runs {
                let session = LanguageModelSession(instructions: instructions)
                let started = Date()
                var cleaned: String
                do {
                    let response = try await session.respond(
                        to: CleanupPrompt.prompt(for: c.transcript),
                        options: GenerationOptions(temperature: 0.2))
                    cleaned = CleanupSanitizer.strip(
                        response.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    // Mirror the engine: polish only what the guard would ship.
                    if !CleanupGuard.looksUnfaithful(raw: c.transcript, cleaned: cleaned) {
                        cleaned = CleanupPolish.apply(cleaned, options: .default, context: context)
                    }
                } catch {
                    cleaned = "<<ERROR: \(error)>>"
                }
                let latency = Date().timeIntervalSince(started)

                let rawWords = words(c.transcript)
                let cleanedWords = words(cleaned)
                let common = lcs(rawWords, cleanedWords)
                let orderScore = cleanedWords.isEmpty ? 0 : Double(common) / Double(cleanedWords.count)
                let retention = rawWords.isEmpty ? 1 : Double(cleanedWords.count) / Double(rawWords.count)
                let tripped = CleanupGuard.looksUnfaithful(raw: c.transcript, cleaned: cleaned)

                var failures: [String] = []
                var ok: Bool? = nil
                if let exact = c.exact {
                    ok = cleaned == exact
                    if ok == false { failures.append("exact: expected \"\(exact)\"") }
                }
                for needle in c.mustContain ?? [] where !cleaned.contains(needle) {
                    ok = false; failures.append("missing: \"\(needle)\"")
                }
                for needle in c.mustNotContain ?? [] where cleaned.contains(needle) {
                    ok = false; failures.append("forbidden: \"\(needle)\"")
                }
                if ok == nil && (c.mustContain != nil || c.mustNotContain != nil) { ok = true }
                if cleaned.hasPrefix("<<ERROR") { ok = false; failures.append("model error") }

                switch ok {
                case .some(true): passed += 1
                case .some(false): failed += 1
                case .none: manual += 1
                }

                let result = EvalResult(
                    id: c.id, run: run, category: category.rawValue,
                    transcript: c.transcript, cleaned: cleaned,
                    ok: ok, failures: failures, guardTripped: tripped,
                    retention: (retention * 100).rounded() / 100,
                    orderScore: (orderScore * 100).rounded() / 100,
                    addedWords: newWords(raw: rawWords, cleaned: cleanedWords),
                    latencySeconds: (latency * 100).rounded() / 100)
                if let line = try? encoder.encode(result) {
                    print(String(data: line, encoding: .utf8)!)
                }
            }
        }
        FileHandle.standardError.write(Data("done: \(passed) passed, \(failed) failed, \(manual) manual-judge\n".utf8))
        #else
        FileHandle.standardError.write(Data("FATAL: FoundationModels not available in this toolchain.\n".utf8))
        exit(1)
        #endif
    }
}
