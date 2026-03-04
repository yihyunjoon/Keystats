import Foundation
import XCTest
@testable import Gizmo

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
  func testRoundTripSaveAndLoad() throws {
    let (store, userDefaults, suiteName) = makeStore()
    defer { clear(userDefaults, suiteName: suiteName) }

    let entries = [
      ClipboardHistoryEntry(
        kind: .text,
        content: "hello",
        copiedAt: Date(timeIntervalSince1970: 100)
      ),
      ClipboardHistoryEntry(
        kind: .url,
        content: "https://example.com",
        copiedAt: Date(timeIntervalSince1970: 200)
      ),
    ]

    store.save(entries)
    let loaded = store.load()

    XCTAssertEqual(loaded, entries)
  }

  func testLoadReturnsEmptyWhenDataIsCorrupted() throws {
    let key = "clipboard.history.v1"
    let (store, userDefaults, suiteName) = makeStore()
    defer { clear(userDefaults, suiteName: suiteName) }

    userDefaults.set(Data("{broken json".utf8), forKey: key)

    let loaded = store.load()

    XCTAssertTrue(loaded.isEmpty)
    XCTAssertNil(userDefaults.data(forKey: key))
  }

  func testClearRemovesPersistedEntries() throws {
    let key = "clipboard.history.v1"
    let (store, userDefaults, suiteName) = makeStore()
    defer { clear(userDefaults, suiteName: suiteName) }

    store.save([
      ClipboardHistoryEntry(
        kind: .text,
        content: "to be deleted",
        copiedAt: Date(timeIntervalSince1970: 10)
      )
    ])

    store.clear()

    XCTAssertNil(userDefaults.data(forKey: key))
    XCTAssertTrue(store.load().isEmpty)
  }

  private func makeStore() -> (UserDefaultsClipboardHistoryStore, UserDefaults, String) {
    let suiteName = "ClipboardHistoryStoreTests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    let store = UserDefaultsClipboardHistoryStore(userDefaults: userDefaults)
    return (store, userDefaults, suiteName)
  }

  private func clear(_ userDefaults: UserDefaults, suiteName: String) {
    userDefaults.removePersistentDomain(forName: suiteName)
  }
}
