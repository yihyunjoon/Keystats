import SwiftData
import SwiftUI

@main
struct KeystatsApp: App {
  @State private var permissionService = InputMonitoringPermissionService()
  @State private var monitorService = KeyboardMonitorService()

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([KeyPressRecord.self])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    do {
      return try ModelContainer(
        for: schema,
        configurations: [modelConfiguration]
      )
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup(id: "main") {
      KeystatsSplitView()
        .frame(minWidth: 600, minHeight: 380)
        .onKeyPress { _ in .handled }
        .environment(permissionService)
        .environment(monitorService)
        .onAppear {
          monitorService.configure(
            with: sharedModelContainer.mainContext
          )

          if permissionService.isGranted {
            _ = monitorService.startMonitoring()
          }
        }
        .onChange(of: permissionService.isGranted) { _, isGranted in
          if isGranted {
            _ = monitorService.startMonitoring()
          }
        }
    }
    .modelContainer(sharedModelContainer)
    .defaultSize(width: 400, height: 600)

    Settings {
      SettingsView()
        .environment(permissionService)
        .environment(monitorService)
        .modelContainer(sharedModelContainer)
    }

    MenuBarExtra(
      String(localized: "Keystats"),
      systemImage: "keyboard"
    ) {
      MenuBarView()
    }
  }
}
