import Testing
import Foundation
@testable import VoiceTypeKit

private func sample(_ text: String, id: UUID = UUID()) -> DictationRecord {
    DictationRecord(id: id, date: Date(timeIntervalSince1970: 0), text: text,
                    transcriptionEngine: .appleOnDevice, cleanupEngine: .ruleBased,
                    timeToText: 0.5)
}

@Suite("Transcript records — schema back-compat")
struct RecordBackCompatTests {
    @Test("a record JSON missing the new fields decodes with defaults")
    func legacyDecodes() throws {
        // Exactly the shape written before source/app/speakingTime existed.
        let legacy = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "date": 0,
          "text": "hello world",
          "transcriptionEngine": "appleOnDevice",
          "cleanupEngine": "ruleBased",
          "timeToText": 0.5
        }
        """.data(using: .utf8)!
        let record = try JSONDecoder().decode(DictationRecord.self, from: legacy)
        #expect(record.text == "hello world")
        #expect(record.source == .microphone)     // defaulted
        #expect(record.sourceFilename == nil)
        #expect(record.appName == nil)
        #expect(record.speakingTime == 0)
    }

    @Test("a record with the new fields round-trips")
    func roundTrip() throws {
        var r = sample("imported text")
        r.source = .importedFile
        r.sourceFilename = "meeting.mp3"
        r.appName = "Slack"
        r.appBundleID = "com.tinyspeck.slackmacgap"
        r.speakingTime = 12.5
        let data = try JSONEncoder().encode(r)
        let back = try JSONDecoder().decode(DictationRecord.self, from: data)
        #expect(back == r)
    }
}

@Suite("Transcript history — cap, order, delete")
struct HistoryRingTests {
    @Test("newest is first and the cap is enforced")
    func capAndOrder() {
        var h = DictationHistory(limit: 3)
        h.add(sample("one"))
        h.add(sample("two"))
        h.add(sample("three"))
        h.add(sample("four"))               // evicts "one"
        #expect(h.records.count == 3)
        #expect(h.records.first?.text == "four")
        #expect(h.records.contains { $0.text == "one" } == false)
    }

    @Test("remove(id:) deletes just that record")
    func remove() {
        let target = UUID()
        var h = DictationHistory(limit: 10)
        h.add(sample("keep", id: UUID()))
        h.add(sample("drop", id: target))
        h.add(sample("keep too", id: UUID()))
        h.remove(id: target)
        #expect(h.records.count == 2)
        #expect(h.records.contains { $0.id == target } == false)
    }
}
