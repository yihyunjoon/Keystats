import SwiftUI

struct LauncherInputView: View {
  // MARK: - Properties

  let onClose: () -> Void

  @State private var query: String = ""
  @FocusState private var isInputFocused: Bool

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
          .font(.system(size: 18, weight: .medium))

        TextField(
          String(localized: "Search apps, files, and commands"),
          text: $query
        )
        .textFieldStyle(.plain)
        .font(.system(size: 24, weight: .medium, design: .rounded))
        .focused($isInputFocused)
      }

      Divider()

      Text(
        query.isEmpty
          ? String(localized: "Type to start searching.")
          : query
      )
      .font(.system(size: 13, weight: .regular, design: .rounded))
      .foregroundStyle(.secondary)
    }
    .padding(16)
    .frame(width: 640)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
    }
    .padding(12)
    .onAppear {
      focusInput()
    }
    .onReceive(NotificationCenter.default.publisher(for: .launcherPanelDidOpen)) { _ in
      query = ""
      focusInput()
    }
    .onExitCommand {
      onClose()
    }
  }

  // MARK: - Focus

  private func focusInput() {
    DispatchQueue.main.async {
      isInputFocused = true
    }
  }
}

#Preview {
  LauncherInputView {}
}
