import AppKit
import SwiftUI

@MainActor
final class LauncherPanelService: NSObject, NSWindowDelegate {
  private enum PanelLayout {
    static let width: CGFloat = 680
    static let height: CGFloat = 320
  }

  // MARK: - Properties

  private let windowManagerService: WindowManagerService
  private let accessibilityPermissionService: AccessibilityPermissionService
  private let configStore: ConfigStore

  private var panel: LauncherPanel?
  private var previousInputSourceID: String?
  private var focusedWindowBeforePanelOpen: AXUIElement?

  // MARK: - Initialization

  init(
    windowManagerService: WindowManagerService,
    accessibilityPermissionService: AccessibilityPermissionService,
    configStore: ConfigStore
  ) {
    self.windowManagerService = windowManagerService
    self.accessibilityPermissionService = accessibilityPermissionService
    self.configStore = configStore
    super.init()
  }

  // MARK: - Panel Control

  func togglePanel() {
    if panel?.isVisible == true {
      hidePanel()
    } else {
      showPanel()
    }
  }

  func hidePanel() {
    restoreInputSourceIfNeeded()
    panel?.orderOut(nil)
    focusedWindowBeforePanelOpen = nil
  }

  func showPanel() {
    if panel == nil {
      panel = createPanel()
    }

    guard let panel else { return }

    focusedWindowBeforePanelOpen = AXUIElement.focusedWindowElement()
    activateEnglishInputSourceIfNeeded()
    panel.setContentSize(NSSize(width: PanelLayout.width, height: PanelLayout.height))
    positionPanelOnActiveScreen(panel)
    panel.makeKeyAndOrderFront(nil)

    NotificationCenter.default.post(
      name: .launcherPanelDidOpen,
      object: nil
    )
  }

  // MARK: - Private

  private func activateEnglishInputSourceIfNeeded() {
    guard configStore.active.launcher.forceEnglishInputSource else {
      previousInputSourceID = nil
      return
    }

    previousInputSourceID = InputSourceService.switchToEnglishInputSource()
  }

  private func restoreInputSourceIfNeeded() {
    guard let previousInputSourceID else { return }
    InputSourceService.selectInputSource(withID: previousInputSourceID)
    self.previousInputSourceID = nil
  }

  private func positionPanelOnActiveScreen(_ panel: NSPanel) {
    let screenPreference = configStore.active.launcher.display
    let targetScreen =
      screenPreference.targetScreen
      ?? NSScreen.main
      ?? NSScreen.screens.first

    guard let targetScreen else { return }

    let screenFrame = targetScreen.frame
    let panelSize = NSSize(width: PanelLayout.width, height: PanelLayout.height)
    let frame = NSRect(
      x: floor(screenFrame.midX - (panelSize.width / 2)),
      y: floor(screenFrame.midY - (panelSize.height / 2)),
      width: panelSize.width,
      height: panelSize.height
    )

    panel.setFrame(frame, display: false)
  }

  private func createPanel() -> LauncherPanel {
    let contentView = LauncherInputView(
      onClose: { [weak self] in
        self?.hidePanel()
      },
      onExecuteCommand: { [weak self] command in
        guard let self else { return .failure(.applyFailed) }
        let result = self.windowManagerService.execute(
          command.action,
          preferredWindowElement: self.focusedWindowBeforePanelOpen
        )

        if case .success = result {
          self.focusedWindowBeforePanelOpen = nil
        }

        return result
      },
      onOpenAccessibilitySettings: { [weak self] in
        self?.accessibilityPermissionService.openSystemSettings()
      }
    )

    let hostingController = NSHostingController(rootView: contentView)

    let panel = LauncherPanel(
      contentRect: NSRect(
        x: 0,
        y: 0,
        width: PanelLayout.width,
        height: PanelLayout.height
      ),
      styleMask: [.nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [
      .fullScreenAuxiliary,
      .transient,
      .moveToActiveSpace,
    ]
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.delegate = self
    panel.contentViewController = hostingController

    return panel
  }

  // MARK: - NSWindowDelegate

  func windowDidResignKey(_ notification: Notification) {
    hidePanel()
  }
}

private final class LauncherPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

extension Notification.Name {
  static let launcherPanelDidOpen = Notification.Name("launcherPanelDidOpen")
}

extension LauncherDisplay {
  var targetScreen: NSScreen? {
    switch self {
    case .primary:
      return NSScreen.screens.first
    case .mouse:
      let mouseLocation = NSEvent.mouseLocation
      return NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
    case .activeWindow:
      return NSScreen.main
    }
  }
}
