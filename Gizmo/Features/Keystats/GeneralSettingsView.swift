import SwiftUI

struct GeneralSettingsView: View {
  @Environment(InputMonitoringPermissionService.self) private
    var permissionService
  @Environment(KeyboardMonitorService.self) private var monitorService

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "Input Monitoring"))
        .font(.headline)

      LabeledContent {
        Button(String(localized: "Open System Settings")) {
          permissionService.openSystemSettings()
        }
      } label: {
        Label {
          Text(
            permissionService.isGranted
              ? String(localized: "Permission Granted")
              : String(localized: "Permission Required")
          )
        } icon: {
          Image(
            systemName: permissionService.isGranted
              ? "checkmark.circle.fill" : "xmark.circle.fill"
          )
          .foregroundStyle(
            permissionService.isGranted ? .green : .red
          )
        }
      }

      Toggle(
        isOn: Binding(
          get: { monitorService.isMonitoring },
          set: { newValue in
            if newValue {
              _ = monitorService.startMonitoring()
            } else {
              monitorService.stopMonitoring()
            }
          }
        )
      ) {
        Text(String(localized: "Monitoring"))
      }
      .disabled(!permissionService.isGranted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      .regularMaterial,
      in: RoundedRectangle(cornerRadius: 12, style: .continuous)
    )
  }
}

#Preview {
  GeneralSettingsView()
    .environment(InputMonitoringPermissionService())
    .environment(KeyboardMonitorService())
}
