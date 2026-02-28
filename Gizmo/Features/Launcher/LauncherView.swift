import KeyboardShortcuts
import SwiftUI

struct LauncherView: View {
  @AppStorage(LauncherScreenPreference.userDefaultsKey)
  private var launcherScreenPreferenceRawValue: String =
    LauncherScreenPreference.defaultValue.rawValue
  @AppStorage(LauncherPreferenceKey.forceEnglishInputSource)
  private var forceEnglishInputSource = false

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

      Section {
        Picker(
          String(localized: "Launcher Display"),
          selection: $launcherScreenPreferenceRawValue
        ) {
          ForEach(LauncherScreenPreference.allCases) { option in
            Text(option.title)
              .tag(option.rawValue)
          }
        }
        .pickerStyle(.menu)

        Text(
          String(
            localized:
              "Choose which display should show the launcher when the global shortcut is pressed."
          )
        )
        .foregroundStyle(.secondary)
        .font(.footnote)
      } header: {
        Text(String(localized: "Display Placement"))
      }

      Section {
        Toggle(
          String(localized: "Force English Input Source"),
          isOn: $forceEnglishInputSource
        )

        Text(
          String(
            localized:
              "When enabled, launcher input uses an English keyboard layout while the launcher is open."
          )
        )
        .foregroundStyle(.secondary)
        .font(.footnote)
      } header: {
        Text(String(localized: "Input Source"))
      }
    }
    .formStyle(.grouped)
    .onAppear {
      guard
        LauncherScreenPreference(rawValue: launcherScreenPreferenceRawValue) == nil
      else {
        return
      }

      launcherScreenPreferenceRawValue = LauncherScreenPreference.defaultValue.rawValue
    }
  }
}

#Preview {
  LauncherView()
}
