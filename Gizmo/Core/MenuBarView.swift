import SwiftUI

struct MenuBarView: View {
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button(String(localized: "Open Gizmo")) {
      openWindow(id: "main")
      NSApplication.shared.activate(ignoringOtherApps: true)
    }
    .keyboardShortcut("o")

    Divider()

    Button(String(localized: "Quit")) {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q")
  }
}

#Preview {
  MenuBarView()
}
