import SwiftUI

enum NavigationItem: Equatable, Hashable, Identifiable {
  case heatmap
  case launcher
  case command
  case clipboard
  case customMenubar
  case workspace
  case windowManager

  static let mainPages: [NavigationItem] = [
    .heatmap,
    .launcher,
    .command,
    .clipboard,
    .customMenubar,
    .workspace,
    .windowManager
  ]

  var id: String {
    switch self {
    case .heatmap: return "Heatmap"
    case .launcher: return "Launcher"
    case .command: return "Command"
    case .clipboard: return "Clipboard"
    case .customMenubar: return "Custom Menubar"
    case .workspace: return "Workspace"
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
    case .command:
      LocalizedStringResource(
        "Command",
        comment: "Title for the Command tab, shown in the sidebar."
      )
    case .clipboard:
      LocalizedStringResource(
        "Clipboard",
        comment: "Title for the Clipboard tab, shown in the sidebar."
      )
    case .customMenubar:
      LocalizedStringResource(
        "Custom Menubar",
        comment: "Title for the Custom Menubar tab, shown in the sidebar."
      )
    case .workspace:
      LocalizedStringResource(
        "Workspace",
        comment: "Title for the Workspace tab, shown in the sidebar."
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
    case .command: "list.bullet.rectangle"
    case .clipboard: "doc.on.clipboard"
    case .customMenubar: "menubar.dock.rectangle"
    case .workspace: "rectangle.3.group"
    case .windowManager: "rectangle.split.2x1"
    }
  }

  @MainActor @ViewBuilder func viewForPage() -> some View {
    switch self {
    case .heatmap: HeatmapView()
    case .launcher: LauncherView()
    case .command: CommandView()
    case .clipboard: ClipboardView()
    case .customMenubar: CustomMenubarSettingsView()
    case .workspace: WorkspaceView()
    case .windowManager: WindowManagerView()
    }
  }
}
