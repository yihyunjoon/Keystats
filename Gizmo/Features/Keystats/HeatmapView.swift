import SwiftData
import SwiftUI

struct HeatmapView: View {
  @Environment(InputMonitoringPermissionService.self) private
    var permissionService
  @Query private var records: [KeyPressRecord]

  private var sortedRecords: [KeyPressRecord] {
    records.sorted { $0.count > $1.count }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if !permissionService.isGranted {
          PermissionCard()
        }
        KeyPressChartView(records: sortedRecords)
        KeyboardHeatmapView(records: records)

        Divider()

        SettingsView()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
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
