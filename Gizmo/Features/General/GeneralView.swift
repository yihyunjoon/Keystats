import AppKit
import SwiftUI

struct GeneralView: View {
  @Environment(ConfigStore.self) private var configStore
  @Environment(LaunchAtLoginService.self) private var launchAtLoginService

  var body: some View {
    Form {
      Section {
        Toggle(
          isOn: Binding(
            get: { launchAtLoginService.isEnabled },
            set: { launchAtLoginService.setEnabled($0) }
          )
        ) {
          Text(String(localized: "Launch Gizmo when you sign in."))
        }
        .disabled(launchAtLoginService.isUpdating)

        Text(launchAtLoginService.statusDescription)
          .font(.footnote)
          .foregroundStyle(.secondary)

        if launchAtLoginService.requiresApproval {
          Button(String(localized: "Open Login Items Settings")) {
            launchAtLoginService.openSystemSettings()
          }
          .buttonStyle(.link)
        }

        if let error = launchAtLoginService.lastError {
          Text(error)
            .foregroundStyle(.red)
            .font(.footnote)
            .textSelection(.enabled)
        }
      } header: {
        Text(String(localized: "Launch at Login"))
      }

      Section {
        LabeledContent(String(localized: "Path"), value: configStore.configURL.path())
          .lineLimit(2)

        HStack(spacing: 8) {
          Button(String(localized: "Open Config")) {
            configStore.openConfigFile()
          }
          .buttonStyle(.bordered)

          Button(String(localized: "Reveal Config")) {
            configStore.revealConfigFile()
          }
          .buttonStyle(.bordered)

          Button(String(localized: "Reload Config")) {
            _ = configStore.reload()
          }
          .buttonStyle(.borderedProminent)
        }

        if let error = configStore.lastLoadError {
          Text(error)
            .foregroundStyle(.red)
            .font(.footnote)
            .textSelection(.enabled)
        }
      } header: {
        Text(String(localized: "Config File"))
      }
    }
    .formStyle(.grouped)
    .onAppear {
      launchAtLoginService.refresh()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      launchAtLoginService.refresh()
    }
  }
}

#Preview {
  GeneralView()
    .environment(ConfigStore())
    .environment(LaunchAtLoginService())
}
