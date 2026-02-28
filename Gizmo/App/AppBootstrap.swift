import SwiftData

@MainActor
struct AppBootstrap {
  let configStore: ConfigStore
  let hotKeyService: GlobalHotKeyService
  let accessibilityPermissionService: AccessibilityPermissionService
  let windowManagerService: WindowManagerService
  let launcherPanelService: LauncherPanelService
  let sharedModelContainer: ModelContainer

  init() {
    let configStore = ConfigStore()
    configStore.bootstrapAndLoad()

    let hotKeyService = GlobalHotKeyService()
    let accessibilityPermissionService = AccessibilityPermissionService()
    let windowManagerService = WindowManagerService(
      permissionService: accessibilityPermissionService
    )
    let launcherPanelService = LauncherPanelService(
      windowManagerService: windowManagerService,
      accessibilityPermissionService: accessibilityPermissionService,
      configStore: configStore
    )

    hotKeyService.onHotKeyPressed = {
      Task { @MainActor in
        launcherPanelService.togglePanel()
      }
    }
    hotKeyService.configure(
      shortcut: configStore.active.launcher.globalHotkey.keyboardShortcut
    )
    configStore.onConfigDidLoad = { config in
      hotKeyService.configure(
        shortcut: config.launcher.globalHotkey.keyboardShortcut
      )
    }

    self.configStore = configStore
    self.hotKeyService = hotKeyService
    self.accessibilityPermissionService = accessibilityPermissionService
    self.windowManagerService = windowManagerService
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
