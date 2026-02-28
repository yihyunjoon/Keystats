import SwiftData
import SwiftUI

struct HeatmapView: View {
  private enum KeystatsPanel: String, CaseIterable, Identifiable {
    case chart
    case heatmap

    var id: Self { self }

    var title: LocalizedStringKey {
      switch self {
      case .chart:
        return "Chart"
      case .heatmap:
        return "Heatmap"
      }
    }
  }

  @Environment(InputMonitoringPermissionService.self) private
    var permissionService
  @Query private var records: [KeyPressRecord]
  @State private var selectedPanel: KeystatsPanel = .chart
  private let panelWidth: CGFloat = 620
  private let panelHeight: CGFloat = 360

  private var sortedRecords: [KeyPressRecord] {
    records.sorted { $0.count > $1.count }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if !permissionService.isGranted {
          PermissionCard()
        }

        VStack(alignment: .leading, spacing: 12) {
          Picker("View", selection: $selectedPanel) {
            ForEach(KeystatsPanel.allCases) { panel in
              Text(panel.title)
                .tag(panel)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .accessibilityLabel("View")

          ZStack(alignment: .topLeading) {
            switch selectedPanel {
            case .chart:
              KeyPressChartView(records: sortedRecords)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .heatmap:
              KeyboardHeatmapView(records: records)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
          }
          .frame(width: panelWidth, height: panelHeight, alignment: .topLeading)
          .clipped()
          .animation(.snappy, value: selectedPanel)
        }

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
