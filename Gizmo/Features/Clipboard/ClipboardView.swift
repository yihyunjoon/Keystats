import SwiftUI

struct ClipboardView: View {
  @Environment(ClipboardHistoryService.self) private var clipboardHistoryService

  @State private var selectedEntryID: ClipboardHistoryEntry.ID?

  private var selectedEntry: ClipboardHistoryEntry? {
    guard let selectedEntryID else {
      return clipboardHistoryService.entries.first
    }

    return clipboardHistoryService.entries.first { $0.id == selectedEntryID }
      ?? clipboardHistoryService.entries.first
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      if clipboardHistoryService.entries.isEmpty {
        emptyState
      } else {
        HSplitView {
          historyList
          detailPane
        }
      }
    }
    .padding(16)
    .onAppear {
      syncSelection(with: clipboardHistoryService.entries)
    }
    .onChange(of: clipboardHistoryService.entries) { _, newEntries in
      syncSelection(with: newEntries)
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      Text(String(localized: "Clipboard History"))
        .font(.title3.weight(.semibold))

      Spacer()

      Text("\(clipboardHistoryService.entries.count)")
        .font(.body.monospacedDigit())
        .foregroundStyle(.secondary)

      Button(String(localized: "Clear All")) {
        clipboardHistoryService.clearAll()
      }
      .buttonStyle(.bordered)
      .disabled(clipboardHistoryService.entries.isEmpty)
    }
  }

  private var emptyState: some View {
    VStack(alignment: .center, spacing: 8) {
      Image(systemName: "doc.on.clipboard")
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(.secondary)

      Text(String(localized: "No clipboard history yet."))
        .font(.headline)

      Text(String(localized: "Copy text to start collecting clipboard history."))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var historyList: some View {
    List(selection: $selectedEntryID) {
      ForEach(clipboardHistoryService.entries) { entry in
        row(for: entry)
          .tag(entry.id)
      }
    }
    .listStyle(.inset)
    .frame(minWidth: 300, idealWidth: 360, maxWidth: 420)
  }

  private var detailPane: some View {
    Group {
      if let entry = selectedEntry {
        ScrollView {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
              kindBadge(for: entry.kind)

              Text(entry.copiedAt, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)

              Spacer()

              Button(String(localized: "Copy")) {
                clipboardHistoryService.copyEntryToPasteboard(entry)
              }
              .buttonStyle(.borderedProminent)
            }

            if entry.kind == .url,
              let url = validatedURL(from: entry.content)
            {
              Link(String(localized: "Open Link"), destination: url)
                .font(.footnote)
            }

            Text(entry.content)
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12)
              .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
        }
      } else {
        Text(String(localized: "Select a clipboard history item."))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private func row(for entry: ClipboardHistoryEntry) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        kindBadge(for: entry.kind)

        Spacer(minLength: 8)

        Text(entry.copiedAt, style: .time)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Text(entry.content)
        .lineLimit(1)
        .truncationMode(.tail)
        .font(.system(size: 12, weight: .regular, design: .rounded))
    }
    .padding(.vertical, 2)
  }

  private func kindBadge(for kind: ClipboardEntryKind) -> some View {
    Text(kindTitle(for: kind))
      .font(.caption2.weight(.semibold))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(kindTint(for: kind).opacity(0.16), in: Capsule())
      .foregroundStyle(kindTint(for: kind))
  }

  private func kindTitle(for kind: ClipboardEntryKind) -> String {
    switch kind {
    case .text:
      return String(localized: "TEXT")
    case .url:
      return String(localized: "URL")
    }
  }

  private func kindTint(for kind: ClipboardEntryKind) -> Color {
    switch kind {
    case .text:
      return .blue
    case .url:
      return .green
    }
  }

  private func validatedURL(from rawString: String) -> URL? {
    guard
      let components = URLComponents(string: rawString),
      let scheme = components.scheme?.lowercased(),
      (scheme == "http" || scheme == "https")
    else {
      return nil
    }

    return components.url
  }

  private func syncSelection(with entries: [ClipboardHistoryEntry]) {
    guard !entries.isEmpty else {
      selectedEntryID = nil
      return
    }

    if let selectedEntryID,
      entries.contains(where: { $0.id == selectedEntryID })
    {
      return
    }

    self.selectedEntryID = entries.first?.id
  }
}

#Preview {
  ClipboardView()
    .environment(ClipboardHistoryService())
}
