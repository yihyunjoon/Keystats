import SwiftData

@MainActor
struct AppBootstrap {
  let hotKeyService: GlobalHotKeyService
  let launcherPanelService: LauncherPanelService
  let sharedModelContainer: ModelContainer

  init() {
    let hotKeyService = GlobalHotKeyService()
    let launcherPanelService = LauncherPanelService()

    hotKeyService.onHotKeyPressed = {
      Task { @MainActor in
        launcherPanelService.togglePanel()
      }
    }
    hotKeyService.configure()

    self.hotKeyService = hotKeyService
    self.launcherPanelService = launcherPanelService
    self.sharedModelContainer = Self.makeSharedModelContainer()
  }

  private static func makeSharedModelContainer() -> ModelContainer {
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
  }
}
