import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Word replacements")
struct WordReplacementsTests {

    @Test("replaces a whole word, ignoring case")
    func wholeWordCaseInsensitive() {
        let dict = [WordReplacement(from: "jason", to: "JSON")]
        #expect(WordReplacements.apply(dict, to: "parse the Jason payload")
            == "parse the JSON payload")
    }

    @Test("multi-word phrases replace as a unit")
    func multiWordPhrase() {
        let dict = [WordReplacement(from: "voice type", to: "VoiceType")]
        #expect(WordReplacements.apply(dict, to: "I built voice type last month")
            == "I built VoiceType last month")
    }

    @Test("never matches inside another word")
    func noSubstringMatch() {
        let dict = [WordReplacement(from: "cat", to: "dog")]
        #expect(WordReplacements.apply(dict, to: "the category of the cat")
            == "the category of the dog")
    }

    @Test("empty or whitespace-only sources are ignored")
    func emptySourceIgnored() {
        let dict = [WordReplacement(from: "  ", to: "boom")]
        #expect(WordReplacements.apply(dict, to: "unchanged text") == "unchanged text")
    }

    @Test("replacement text is inserted literally, including regex characters")
    func literalReplacement() {
        let dict = [WordReplacement(from: "dollars", to: "$100")]
        #expect(WordReplacements.apply(dict, to: "it costs dollars") == "it costs $100")
    }

    @Test("replacements apply in order")
    func appliesInOrder() {
        let dict = [
            WordReplacement(from: "foo", to: "bar"),
            WordReplacement(from: "bar", to: "baz"),
        ]
        #expect(WordReplacements.apply(dict, to: "foo") == "baz")
    }

    @Test("empty dictionary is a no-op")
    func emptyDictionary() {
        #expect(WordReplacements.apply([], to: "hello") == "hello")
    }
}

@Suite("Settings compatibility")
struct SettingsWordReplacementTests {

    @Test("settings saved before wordReplacements existed still decode")
    func decodesLegacySettings() throws {
        // Encode current settings, strip the new key to simulate an old save.
        let data = try JSONEncoder().encode(AppSettings.default)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "wordReplacements")
        let legacy = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacy)
        #expect(decoded.wordReplacements.isEmpty)
        #expect(decoded.cleanupEngine == AppSettings.default.cleanupEngine)
    }

    @Test("wordReplacements round-trip through Codable")
    func roundTrip() throws {
        var settings = AppSettings.default
        settings.wordReplacements = [WordReplacement(from: "gh", to: "GitHub")]
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded == settings)
    }
}
