import SwiftData
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "General"), systemImage: "gear") {
                GeneralSettingsView()
            }
            Tab(String(localized: "Data"), systemImage: "externaldrive") {
                DataSettingsView()
            }
        }
        .frame(width: 380, height: 480)
    }
}

#Preview {
    SettingsView()
        .environment(InputMonitoringPermissionService())
        .environment(KeyboardMonitorService())
        .modelContainer(for: KeyPressRecord.self, inMemory: true)
}
