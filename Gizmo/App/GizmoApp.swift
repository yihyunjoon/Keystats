import AppKit
import SwiftData
import SwiftUI

@main
struct GizmoApp: App {
  @State private var appEnvironment = AppEnvironment()
  private let bootstrap: AppBootstrap

  init() {
    self.bootstrap = AppBootstrap()
  }

  var body: some Scene {
    WindowGroup(id: "main") {
      GizmoSplitView()
        .frame(minWidth: 900, minHeight: 550)
        .onKeyPress { _ in .handled }
        .background {
          MainWindowOpenActionRegistrar(
            launcherPanelService: bootstrap.launcherPanelService
          )
        }
        .environment(bootstrap.configStore)
        .environment(appEnvironment.permissionService)
        .environment(appEnvironment.monitorService)
        .environment(bootstrap.accessibilityPermissionService)
        .environment(bootstrap.windowManagerService)
        .onAppear {
          appEnvironment.configureMonitoring(
            container: bootstrap.sharedModelContainer,
            shouldAutoStart: bootstrap.configStore.active.keystats.autoStartMonitoring
          )
        }
        .onChange(of: bootstrap.configStore.active.keystats.autoStartMonitoring) {
          _, shouldAutoStart in
          appEnvironment.applyMonitoringPolicy(shouldAutoStart: shouldAutoStart)
        }
        .onChange(of: appEnvironment.permissionService.isGranted) { _, isGranted in
          appEnvironment.handlePermissionChange(
            isGranted,
            shouldAutoStart: bootstrap.configStore.active.keystats.autoStartMonitoring
          )
        }
    }
    .modelContainer(bootstrap.sharedModelContainer)
    .defaultSize(width: 900, height: 550)

    MenuBarExtra(
      String(localized: "Gizmo"),
      systemImage: "keyboard"
    ) {
      MenuBarView()
        .environment(bootstrap.configStore)
    }
  }
}

private struct MainWindowOpenActionRegistrar: View {
  @Environment(\.openWindow) private var openWindow

  let launcherPanelService: LauncherPanelService

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .onAppear {
        launcherPanelService.onOpenMainWindowRequest = { [openWindow] in
          openWindow(id: "main")
          NSApplication.shared.activate(ignoringOtherApps: true)
        }
      }
  }
}
