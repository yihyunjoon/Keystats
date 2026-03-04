import Foundation

enum ClipboardEntryKind: String, Codable, Equatable {
  case text
  case url
}

struct ClipboardHistoryEntry: Codable, Equatable, Identifiable {
  var id: UUID
  var kind: ClipboardEntryKind
  var content: String
  var copiedAt: Date

  init(
    id: UUID = UUID(),
    kind: ClipboardEntryKind,
    content: String,
    copiedAt: Date
  ) {
    self.id = id
    self.kind = kind
    self.content = content
    self.copiedAt = copiedAt
  }
}
