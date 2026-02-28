import SwiftData
import SwiftUI

struct SettingsView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      GeneralSettingsView()
      DataSettingsView()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  SettingsView()
    .environment(InputMonitoringPermissionService())
    .environment(KeyboardMonitorService())
    .modelContainer(for: KeyPressRecord.self, inMemory: true)
}
