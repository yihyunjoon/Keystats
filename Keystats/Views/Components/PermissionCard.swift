import SwiftUI

struct PermissionCard: View {
  @Environment(InputMonitoringPermissionService.self) private
    var permissionService

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.orange)
        Text(String(localized: "Permission Required"))
          .fontWeight(.semibold)
      }
      .font(.headline)

      Text(
        String(
          localized:
            "Input Monitoring permission is required to monitor keyboard input."
        )
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)

      HStack {
        Button(String(localized: "Grant Access")) {
          permissionService.requestPermission()
        }
        .buttonStyle(.borderedProminent)

        Button(String(localized: "Open System Settings")) {
          permissionService.openSystemSettings()
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.orange.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
