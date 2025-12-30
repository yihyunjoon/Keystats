import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(String(localized: "Open Keystats")) {
            openWindow(id: "main")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("o")

        SettingsLink {
            Text(String(localized: "Settings..."))
        }
        .keyboardShortcut(",")

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
