import AppKit
import OSLog

@MainActor
final class CustomMenubarRuntimeService: NSObject, CustomMenubarPresenting {
  private let logger = Logger(subsystem: "com.yihyunjoon.Gizmo", category: "CustomMenubar")

  private var spaceManager: SkyLightSpaceManager?
  private var windows: [String: CustomMenubarWindowController] = [:]
  private var skylightAttachedScreenIDs: Set<String> = []

  private var screenObserver: NSObjectProtocol?
  private var activeSpaceObserver: NSObjectProtocol?

  private let model = CustomMenubarModel()

  private(set) var isRunning = false
  private(set) var config: CustomMenubarConfig = .default

  var onOpenMainWindow: ((CGPoint?) -> Void)?
  var onReloadConfig: (() -> Void)?
  var onTogglePanel: (() -> Void)?
  var onQuit: (() -> Void)?

  override init() {
    super.init()

    onOpenMainWindow = { [weak self] targetCenter in
      self?.focusExistingMainWindow(at: targetCenter)
    }
    onReloadConfig = {}
    onTogglePanel = {}
    onQuit = {
      NSApplication.shared.terminate(nil)
    }
  }

  func setOpenMainWindowHandler(_ handler: @escaping (CGPoint?) -> Void) {
    onOpenMainWindow = handler
  }

  func setReloadConfigHandler(_ handler: @escaping () -> Void) {
    onReloadConfig = handler
  }

  func setTogglePanelHandler(_ handler: @escaping () -> Void) {
    onTogglePanel = handler
  }

  func setQuitHandler(_ handler: @escaping () -> Void) {
    onQuit = handler
  }

  func start() {
    guard !isRunning else { return }

    isRunning = true
    model.start()
    observeScreenChangesIfNeeded()
    observeSpaceChangesIfNeeded()
    reconcileWindows()
  }

  func stop() {
    guard isRunning else { return }

    isRunning = false
    removeObservers()
    tearDownWindows()
    model.stop()
  }

  func apply(config: CustomMenubarConfig) {
    self.config = config
    model.apply(config: config)

    guard isRunning else { return }
    reconcileWindows()
  }

  func reconfigureForDisplayChanges() {
    guard isRunning else { return }
    reconcileWindows()
  }

  private func observeScreenChangesIfNeeded() {
    guard screenObserver == nil else { return }

    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.reconfigureForDisplayChanges()
    }
  }

  private func observeSpaceChangesIfNeeded() {
    guard activeSpaceObserver == nil else { return }

    activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.reconfigureForDisplayChanges()
    }
  }

  private func removeObservers() {
    if let screenObserver {
      NotificationCenter.default.removeObserver(screenObserver)
      self.screenObserver = nil
    }

    if let activeSpaceObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
      self.activeSpaceObserver = nil
    }
  }

  private func reconcileWindows() {
    guard isRunning else { return }

    guard config.enabled else {
      tearDownWindows()
      return
    }

    let hasSkyLight = ensureSpaceManager()
    if !hasSkyLight {
      skylightAttachedScreenIDs.removeAll()
    }

    let targetScreens = resolvedScreens(scope: config.displayScope)
    guard !targetScreens.isEmpty else {
      tearDownWindows()
      return
    }

    let targetIDs = Set(targetScreens.map(screenIdentifier(_:)))

    for (id, controller) in windows where !targetIDs.contains(id) {
      controller.close()
      windows.removeValue(forKey: id)
      skylightAttachedScreenIDs.remove(id)
    }

    let items = menuItems()

    for screen in targetScreens {
      let id = screenIdentifier(screen)

      if let controller = windows[id] {
        controller.update(screen: screen, model: model, items: items, config: config)
        if hasSkyLight, !skylightAttachedScreenIDs.contains(id), let window = controller.window {
          attachWindowToSkyLight(window, screenID: id, attemptsRemaining: 8)
        }
        if shouldHideInFullscreen(for: screen, screenID: id) {
          controller.hide()
        } else {
          controller.show()
        }
        continue
      }

      let controller = CustomMenubarWindowController(
        screen: screen,
        model: model,
        items: items,
        config: config
      )

      windows[id] = controller

      guard let window = controller.window else {
        logger.error("Failed to resolve NSWindow for screen id=\(id, privacy: .public)")
        controller.close()
        windows.removeValue(forKey: id)
        continue
      }

      if hasSkyLight {
        attachWindowToSkyLight(window, screenID: id, attemptsRemaining: 8)
      }

      if shouldHideInFullscreen(for: screen, screenID: id) {
        controller.hide()
      } else {
        controller.show()
      }
    }
  }

  private func ensureSpaceManager() -> Bool {
    if spaceManager != nil { return true }

    do {
      spaceManager = try SkyLightSpaceManager()
      return true
    } catch {
      logger.error("SkyLight initialization failed: \(error.localizedDescription, privacy: .public)")
      spaceManager = nil
      return false
    }
  }

  private func tearDownWindows() {
    for windowController in windows.values {
      windowController.close()
    }

    windows.removeAll()
    skylightAttachedScreenIDs.removeAll()
    spaceManager = nil
  }

  private func attachWindowToSkyLight(
    _ window: NSWindow,
    screenID: String,
    attemptsRemaining: Int
  ) {
    guard let spaceManager else { return }

    do {
      try spaceManager.attachWindow(window)
      skylightAttachedScreenIDs.insert(screenID)
    } catch {
      if attemptsRemaining > 0 {
        let retryDelay = DispatchTimeInterval.milliseconds(60)
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self, weak window] in
          guard let self, let window else { return }
          self.attachWindowToSkyLight(
            window,
            screenID: screenID,
            attemptsRemaining: attemptsRemaining - 1
          )
        }
        return
      }

      logger.error(
        "SkyLight attach failed for screen id=\(screenID, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      skylightAttachedScreenIDs.remove(screenID)
      logger.error(
        "Keeping overlay window visible without SkyLight space binding for screen id=\(screenID, privacy: .public)"
      )
      windows[screenID]?.show()
    }
  }

  private func shouldHideInFullscreen(for screen: NSScreen, screenID: String) -> Bool {
    guard skylightAttachedScreenIDs.contains(screenID) else {
      return false
    }

    guard let spaceManager else {
      return false
    }

    return spaceManager.isFullscreen(screen: screen)
  }

  private func resolvedScreens(scope: CustomMenubarDisplayScope) -> [NSScreen] {
    switch scope {
    case .all:
      return NSScreen.screens

    case .active:
      if let screen = screenUnderMousePointer() {
        return [screen]
      }

      if let mainScreen = NSScreen.main {
        return [mainScreen]
      }

      return Array(NSScreen.screens.prefix(1))

    case .primary:
      if let mainScreen = NSScreen.screens.first {
        return [mainScreen]
      }

      return []
    }
  }

  private func screenUnderMousePointer() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
  }

  private func menuItems() -> [CustomMenubarItem] {
    let openAction = onOpenMainWindow ?? { [weak self] targetCenter in
      self?.focusExistingMainWindow(at: targetCenter)
    }
    let reloadAction = onReloadConfig ?? {}
    let toggleAction = onTogglePanel ?? {}
    let quitAction = onQuit ?? { NSApplication.shared.terminate(nil) }

    return [
      CustomMenubarItem(
        id: "open-gizmo",
        title: String(localized: "Open Gizmo"),
        systemImage: "rectangle.stack",
        action: { [weak self] in
          openAction(self?.screenUnderMousePointer()?.frame.center)
        }
      ),
      CustomMenubarItem(
        id: "toggle-launcher",
        title: String(localized: "Toggle Launcher"),
        systemImage: "command.square",
        action: { toggleAction() }
      ),
      CustomMenubarItem(
        id: "reload-config",
        title: String(localized: "Reload Config"),
        systemImage: "arrow.clockwise",
        action: { reloadAction() }
      ),
      CustomMenubarItem(
        id: "quit",
        title: String(localized: "Quit"),
        systemImage: "power",
        action: { quitAction() }
      ),
    ]
  }

  private func screenIdentifier(_ screen: NSScreen) -> String {
    if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
      return number.stringValue
    }

    return UUID().uuidString
  }

  private func focusExistingMainWindow(at targetCenter: CGPoint?) {
    guard let window = resolveMainWindow() else { return }

    centerWindow(window, at: targetCenter)

    if window.isMiniaturized {
      window.deminiaturize(nil)
    }

    NSApplication.shared.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }

  private func resolveMainWindow() -> NSWindow? {
    if let taggedCandidate = NSApplication.shared.orderedWindows.first(where: isTaggedMainWindow(_:)) {
      return taggedCandidate
    }

    if let taggedCandidate = NSApplication.shared.windows.first(where: isTaggedMainWindow(_:)) {
      return taggedCandidate
    }

    if let orderedCandidate = NSApplication.shared.orderedWindows.first(where: isFallbackMainWindow(_:)) {
      return orderedCandidate
    }

    return NSApplication.shared.windows.first(where: isFallbackMainWindow(_:))
  }

  private func isTaggedMainWindow(_ window: NSWindow) -> Bool {
    window.identifier == MainWindowIdentity.identifier
  }

  private func isFallbackMainWindow(_ window: NSWindow) -> Bool {
    if window is NSPanel { return false }
    if !window.canBecomeMain { return false }

    return true
  }

  private func centerWindow(_ window: NSWindow, at targetCenter: CGPoint?) {
    guard let targetCenter else { return }

    var frame = window.frame
    frame.origin.x = floor(targetCenter.x - (frame.width / 2))
    frame.origin.y = floor(targetCenter.y - (frame.height / 2))
    window.setFrameOrigin(frame.origin)
  }
}

private extension CGRect {
  var center: CGPoint {
    CGPoint(x: midX, y: midY)
  }
}
