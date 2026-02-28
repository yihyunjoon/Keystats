import KeyboardShortcuts
import SwiftUI

struct LauncherView: View {
  var body: some View {
    Form {
      Section {
        KeyboardShortcuts.Recorder(
          String(localized: "Launcher Hot Key"),
          name: .toggleLauncher
        )

        Text(
          String(
            localized:
              "Set a global shortcut to open or close the launcher input window."
          )
        )
        .foregroundStyle(.secondary)
        .font(.footnote)
      } header: {
        Text(String(localized: "Global Shortcut"))
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  LauncherView()
}
