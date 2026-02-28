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
        .frame(minWidth: 600, minHeight: 380)
        .onKeyPress { _ in .handled }
        .environment(bootstrap.configStore)
        .environment(appEnvironment.permissionService)
        .environment(appEnvironment.monitorService)
        .environment(bootstrap.accessibilityPermissionService)
        .environment(bootstrap.windowManagerService)
        .onAppear {
          appEnvironment.configureMonitoring(
            context: bootstrap.sharedModelContainer.mainContext,
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
    .defaultSize(width: 400, height: 600)

    MenuBarExtra(
      String(localized: "Gizmo"),
      systemImage: "keyboard"
    ) {
      MenuBarView()
        .environment(bootstrap.configStore)
    }
  }
}
