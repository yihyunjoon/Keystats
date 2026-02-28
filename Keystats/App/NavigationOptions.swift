import SwiftUI

enum NavigationItem: Equatable, Hashable, Identifiable {
  case dashboard
  case heatmap
  case launcher

  static let mainPages: [NavigationItem] = [.dashboard, .heatmap, .launcher]

  var id: String {
    switch self {
    case .dashboard: return "Dashboard"
    case .heatmap: return "Heatmap"
    case .launcher: return "Launcher"
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
    case .launcher:
      LocalizedStringResource(
        "Launcher",
        comment: "Title for the Launcher tab, shown in the sidebar."
      )
    }
  }

  var symbolName: String {
    switch self {
    case .dashboard: "chart.bar"
    case .heatmap: "keyboard"
    case .launcher: "command.square"
    }
  }

  @MainActor @ViewBuilder func viewForPage() -> some View {
    switch self {
    case .dashboard: DashboardView()
    case .heatmap: HeatmapView()
    case .launcher: LauncherView()
    }
  }
}
