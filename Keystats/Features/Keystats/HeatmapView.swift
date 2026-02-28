import SwiftData
import SwiftUI

struct HeatmapView: View {
  @Environment(InputMonitoringPermissionService.self) private
    var permissionService
  @Query private var records: [KeyPressRecord]

  var body: some View {
    ScrollView {
      VStack {
        if !permissionService.isGranted {
          PermissionCard()
        }
        KeyboardHeatmapView(records: records)
      }
      .padding()
    }
  }
}

#Preview {
  HeatmapView()
    .environment(InputMonitoringPermissionService())
    .environment(KeyboardMonitorService())
    .modelContainer(for: KeyPressRecord.self, inMemory: true)
}
