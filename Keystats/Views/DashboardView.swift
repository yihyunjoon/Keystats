import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(InputMonitoringPermissionService.self) private
        var permissionService
    @Query(sort: \KeyPressRecord.count, order: .reverse) private var records:
        [KeyPressRecord]

    var body: some View {
        ScrollView {
            VStack {
                if !permissionService.isGranted {
                    PermissionCard()
                }
                KeyPressChartView(records: records)
            }
            .padding()
        }
    }
}

#Preview {
    DashboardView()
        .environment(InputMonitoringPermissionService())
        .environment(KeyboardMonitorService())
        .modelContainer(for: KeyPressRecord.self, inMemory: true)
}
