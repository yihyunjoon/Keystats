import Foundation

protocol ClipboardHistoryStore {
  func load() -> [ClipboardHistoryEntry]
  func save(_ entries: [ClipboardHistoryEntry])
  func clear()
}

final class UserDefaultsClipboardHistoryStore: ClipboardHistoryStore {
  private enum Storage {
    static let key = "clipboard.history.v1"
  }

  private let userDefaults: UserDefaults
  private let storageKey: String
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(
    userDefaults: UserDefaults = .standard,
    storageKey: String = Storage.key
  ) {
    self.userDefaults = userDefaults
    self.storageKey = storageKey
  }

  func load() -> [ClipboardHistoryEntry] {
    guard let data = userDefaults.data(forKey: storageKey) else {
      return []
    }

    do {
      return try decoder.decode([ClipboardHistoryEntry].self, from: data)
    } catch {
      userDefaults.removeObject(forKey: storageKey)
      return []
    }
  }

  func save(_ entries: [ClipboardHistoryEntry]) {
    do {
      let data = try encoder.encode(entries)
      userDefaults.set(data, forKey: storageKey)
    } catch {
      assertionFailure("Failed to persist clipboard history: \(error)")
    }
  }

  func clear() {
    userDefaults.removeObject(forKey: storageKey)
  }
}
