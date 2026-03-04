import AppKit
import Foundation
import Observation

private let clipboardHistoryMaxEntries = 100

protocol ClipboardPasteboard {
  var changeCount: Int { get }

  func string(for type: NSPasteboard.PasteboardType) -> String?
  func clearContents()
  @discardableResult
  func setString(_ string: String, for type: NSPasteboard.PasteboardType) -> Bool
}

final class SystemClipboardPasteboard: ClipboardPasteboard {
  private let pasteboard: NSPasteboard

  init(pasteboard: NSPasteboard = .general) {
    self.pasteboard = pasteboard
  }

  var changeCount: Int {
    pasteboard.changeCount
  }

  func string(for type: NSPasteboard.PasteboardType) -> String? {
    pasteboard.string(forType: type)
  }

  func clearContents() {
    pasteboard.clearContents()
  }

  @discardableResult
  func setString(_ string: String, for type: NSPasteboard.PasteboardType) -> Bool {
    pasteboard.setString(string, forType: type)
  }
}

@Observable
@MainActor
final class ClipboardHistoryService {
  private(set) var entries: [ClipboardHistoryEntry]
  private(set) var isMonitoring: Bool = false

  private let store: ClipboardHistoryStore
  private let pasteboard: ClipboardPasteboard
  private let now: () -> Date
  private let pollingInterval: TimeInterval

  private var timer: Timer?
  private var lastChangeCount: Int

  init(
    store: ClipboardHistoryStore? = nil,
    pasteboard: ClipboardPasteboard? = nil,
    now: @escaping () -> Date = Date.init,
    pollingInterval: TimeInterval = 0.5
  ) {
    self.store = store ?? UserDefaultsClipboardHistoryStore()
    self.pasteboard = pasteboard ?? SystemClipboardPasteboard()
    self.now = now
    self.pollingInterval = pollingInterval

    let loadedEntries = self.store.load()
    let limitedEntries = Array(loadedEntries.prefix(clipboardHistoryMaxEntries))
    self.entries = limitedEntries
    self.lastChangeCount = self.pasteboard.changeCount

    if limitedEntries.count != loadedEntries.count {
      self.store.save(limitedEntries)
    }
  }

  func startMonitoring() {
    guard !isMonitoring else { return }

    isMonitoring = true
    lastChangeCount = pasteboard.changeCount
    startTimer()
  }

  func stopMonitoring() {
    guard isMonitoring else { return }

    timer?.invalidate()
    timer = nil
    isMonitoring = false
  }

  func clearAll() {
    entries = []
    store.clear()
  }

  func copyEntryToPasteboard(_ entry: ClipboardHistoryEntry) {
    pasteboard.clearContents()
    _ = pasteboard.setString(entry.content, for: .string)
    lastChangeCount = pasteboard.changeCount
  }

  // Internal for deterministic tests.
  func pollIfChanged() {
    let currentChangeCount = pasteboard.changeCount
    guard currentChangeCount != lastChangeCount else { return }

    lastChangeCount = currentChangeCount

    guard let rawString = pasteboard.string(for: .string) else {
      return
    }

    ingest(rawString)
  }

  private func startTimer() {
    timer?.invalidate()

    guard pollingInterval > 0 else { return }

    let timer = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.pollIfChanged()
      }
    }

    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func ingest(_ rawString: String) {
    let trimmed = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    let kind = classifyKind(for: trimmed)
    let copiedAt = now()

    if var latestEntry = entries.first,
      latestEntry.kind == kind,
      latestEntry.content == trimmed
    {
      latestEntry.copiedAt = copiedAt
      entries[0] = latestEntry
      store.save(entries)
      return
    }

    entries.insert(
      ClipboardHistoryEntry(kind: kind, content: trimmed, copiedAt: copiedAt),
      at: 0
    )

    if entries.count > clipboardHistoryMaxEntries {
      entries.removeLast(entries.count - clipboardHistoryMaxEntries)
    }

    store.save(entries)
  }

  private func classifyKind(for content: String) -> ClipboardEntryKind {
    guard
      let components = URLComponents(string: content),
      let scheme = components.scheme?.lowercased(),
      (scheme == "http" || scheme == "https"),
      components.host != nil
    else {
      return .text
    }

    return .url
  }
}
