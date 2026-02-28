import SwiftData
import SwiftUI

@main
struct KeystatsApp: App {
  @State private var appEnvironment = AppEnvironment()
  private let bootstrap: AppBootstrap

  init() {
    self.bootstrap = AppBootstrap()
  }

  var body: some Scene {
    WindowGroup(id: "main") {
      KeystatsSplitView()
        .frame(minWidth: 600, minHeight: 380)
        .onKeyPress { _ in .handled }
        .environment(appEnvironment.permissionService)
        .environment(appEnvironment.monitorService)
        .onAppear {
          appEnvironment.configureMonitoring(
            context: bootstrap.sharedModelContainer.mainContext
          )
        }
        .onChange(of: appEnvironment.permissionService.isGranted) { _, isGranted in
          appEnvironment.handlePermissionChange(isGranted)
        }
    }
    .modelContainer(bootstrap.sharedModelContainer)
    .defaultSize(width: 400, height: 600)

    Settings {
      SettingsView()
        .environment(appEnvironment.permissionService)
        .environment(appEnvironment.monitorService)
        .modelContainer(bootstrap.sharedModelContainer)
    }

    MenuBarExtra(
      String(localized: "Keystats"),
      systemImage: "keyboard"
    ) {
      MenuBarView()
    }
  }
}
