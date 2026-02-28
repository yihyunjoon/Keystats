import SwiftUI

enum NavigationItem: Equatable, Hashable, Identifiable {
  case heatmap
  case launcher
  case windowManager

  static let mainPages: [NavigationItem] = [.heatmap, .launcher, .windowManager]

  var id: String {
    switch self {
    case .heatmap: return "Heatmap"
    case .launcher: return "Launcher"
    case .windowManager: return "WindowManager"
    }
  }

  var name: LocalizedStringResource {
    switch self {
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
    case .windowManager:
      LocalizedStringResource(
        "Window Manager",
        comment: "Title for the Window Manager tab, shown in the sidebar."
      )
    }
  }

  var symbolName: String {
    switch self {
    case .heatmap: "keyboard"
    case .launcher: "command.square"
    case .windowManager: "rectangle.split.2x1"
    }
  }

  @MainActor @ViewBuilder func viewForPage() -> some View {
    switch self {
    case .heatmap: HeatmapView()
    case .launcher: LauncherView()
    case .windowManager: WindowManagerView()
    }
  }
}
