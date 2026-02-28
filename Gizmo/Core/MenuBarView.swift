import SwiftUI

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(ConfigStore.self) private var configStore

  var body: some View {
    Button(String(localized: "Open Gizmo")) {
      openWindow(id: "main")
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
    .keyboardShortcut("o")

    Button(String(localized: "Reload Config")) {
      _ = configStore.reload()
    }
    .keyboardShortcut("r")

    Divider()

    Button(String(localized: "Quit")) {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q")
  }
}

#Preview {
  MenuBarView()
    .environment(ConfigStore())
}
