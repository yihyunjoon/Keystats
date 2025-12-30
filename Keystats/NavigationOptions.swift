import SwiftUI

enum NavigationItem: Equatable, Hashable, Identifiable {
  case dashboard
  case heatmap

  static let mainPages: [NavigationItem] = [.dashboard, .heatmap]

  var id: String {
    switch self {
    case .dashboard: return "Dashboard"
    case .heatmap: return "Heatmap"
    }
  }

  var name: LocalizedStringResource {
    switch self {
    case .dashboard:
      LocalizedStringResource(
        "Dashboard",
        comment: "Title for the Dashboard tab, shown in the sidebar."
      )
    case .heatmap:
      LocalizedStringResource(
        "Heatmap",
        comment: "Title for the Heatmap tab, shown in the sidebar."
      )
    }
  }

  var symbolName: String {
    switch self {
    case .dashboard: "chart.bar"
    case .heatmap: "keyboard"
    }
  }

  @MainActor @ViewBuilder func viewForPage() -> some View {
    switch self {
    case .dashboard: DashboardView()
    case .heatmap: HeatmapView()
    }
  }
}
