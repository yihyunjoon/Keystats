import AppKit
import XCTest
@testable import Gizmo

@MainActor
final class ClipboardHistoryServiceTests: XCTestCase {
  func testPollCapturesTextEntry() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()
    var nowDate = Date(timeIntervalSince1970: 100)

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      now: { nowDate },
      pollingInterval: 10
    )

    pasteboard.simulateIncomingString("hello")
    service.pollIfChanged()

    XCTAssertEqual(service.entries.count, 1)
    XCTAssertEqual(service.entries.first?.kind, .text)
    XCTAssertEqual(service.entries.first?.content, "hello")
  }

  func testPollCapturesURLAsURLKind() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      pollingInterval: 10
    )

    pasteboard.simulateIncomingString("https://example.com/path")
    service.pollIfChanged()

    XCTAssertEqual(service.entries.count, 1)
    XCTAssertEqual(service.entries.first?.kind, .url)
  }

  func testConsecutiveDuplicatesAreMerged() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()
    var nowDate = Date(timeIntervalSince1970: 100)

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      now: { nowDate },
      pollingInterval: 10
    )

    pasteboard.simulateIncomingString("same")
    service.pollIfChanged()

    nowDate = Date(timeIntervalSince1970: 200)
    pasteboard.simulateIncomingString("same")
    service.pollIfChanged()

    XCTAssertEqual(service.entries.count, 1)
    XCTAssertEqual(service.entries.first?.content, "same")
    XCTAssertEqual(service.entries.first?.copiedAt, nowDate)
  }

  func testHistoryIsCappedAtOneHundredEntries() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()
    var nowDate = Date(timeIntervalSince1970: 0)

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      now: { nowDate },
      pollingInterval: 10
    )

    for index in 0...100 {
      nowDate = Date(timeIntervalSince1970: Double(index))
      pasteboard.simulateIncomingString("value-\(index)")
      service.pollIfChanged()
    }

    XCTAssertEqual(service.entries.count, 100)
    XCTAssertEqual(service.entries.first?.content, "value-100")
    XCTAssertEqual(service.entries.last?.content, "value-1")
  }

  func testClearAllClearsInMemoryAndPersistedData() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      pollingInterval: 10
    )

    pasteboard.simulateIncomingString("value")
    service.pollIfChanged()

    service.clearAll()

    XCTAssertTrue(service.entries.isEmpty)
    XCTAssertTrue(store.persistedEntries.isEmpty)
    XCTAssertEqual(store.clearCallCount, 1)
  }

  func testNonStringOrBlankValuesAreIgnored() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      pollingInterval: 10
    )

    pasteboard.simulateIncomingString(nil)
    service.pollIfChanged()

    pasteboard.simulateIncomingString("   \n\t  ")
    service.pollIfChanged()

    XCTAssertTrue(service.entries.isEmpty)
  }

  func testCopyEntryWritesToPasteboard() {
    let store = InMemoryClipboardHistoryStore()
    let pasteboard = MockClipboardPasteboard()

    let service = ClipboardHistoryService(
      store: store,
      pasteboard: pasteboard,
      pollingInterval: 10
    )

    let entry = ClipboardHistoryEntry(
      kind: .text,
      content: "copied-text",
      copiedAt: Date(timeIntervalSince1970: 1)
    )

    service.copyEntryToPasteboard(entry)

    XCTAssertEqual(pasteboard.writtenStrings.last, "copied-text")
    XCTAssertEqual(pasteboard.string(for: .string), "copied-text")
  }
}

private final class InMemoryClipboardHistoryStore: ClipboardHistoryStore {
  var persistedEntries: [ClipboardHistoryEntry] = []
  var clearCallCount = 0

  func load() -> [ClipboardHistoryEntry] {
    persistedEntries
  }

  func save(_ entries: [ClipboardHistoryEntry]) {
    persistedEntries = entries
  }

  func clear() {
    clearCallCount += 1
    persistedEntries = []
  }
}

private final class MockClipboardPasteboard: ClipboardPasteboard {
  var changeCount = 0

  private var storedString: String?
  private(set) var writtenStrings: [String] = []

  func string(for type: NSPasteboard.PasteboardType) -> String? {
    storedString
  }

  func clearContents() {
    storedString = nil
    changeCount += 1
  }

  @discardableResult
  func setString(_ string: String, for type: NSPasteboard.PasteboardType) -> Bool {
    storedString = string
    writtenStrings.append(string)
    changeCount += 1
    return true
  }

  func simulateIncomingString(_ string: String?) {
    storedString = string
    changeCount += 1
  }
}
