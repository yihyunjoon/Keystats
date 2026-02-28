import AppKit
import SwiftUI

@MainActor
final class LauncherPanelService: NSObject, NSWindowDelegate {
  // MARK: - Properties

  private let windowManagerService: WindowManagerService
  private let accessibilityPermissionService: AccessibilityPermissionService

  private var panel: LauncherPanel?
  private var previousInputSourceID: String?
  private var focusedWindowBeforePanelOpen: AXUIElement?

  // MARK: - Initialization

  init(
    windowManagerService: WindowManagerService,
    accessibilityPermissionService: AccessibilityPermissionService
  ) {
    self.windowManagerService = windowManagerService
    self.accessibilityPermissionService = accessibilityPermissionService
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
    positionPanelOnActiveScreen(panel)
    panel.makeKeyAndOrderFront(nil)

    NotificationCenter.default.post(
      name: .launcherPanelDidOpen,
      object: nil
    )
  }

  // MARK: - Private

  private func activateEnglishInputSourceIfNeeded() {
    guard UserDefaults.standard.bool(forKey: LauncherPreferenceKey.forceEnglishInputSource) else {
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
    let screenPreference = LauncherScreenPreference.current
    let targetScreen =
      screenPreference.targetScreen
      ?? NSScreen.main
      ?? NSScreen.screens.first

    guard let targetScreen else { return }

    let screenFrame = targetScreen.frame
    let panelSize = panel.frame.size
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
      contentRect: NSRect(x: 0, y: 0, width: 680, height: 320),
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

enum LauncherScreenPreference: String, CaseIterable, Identifiable {
  case primary
  case mouse
  case activeWindow

  static let userDefaultsKey = LauncherPreferenceKey.screenPlacement
  static let defaultValue: LauncherScreenPreference = .activeWindow

  var id: String { rawValue }

  var title: LocalizedStringResource {
    switch self {
    case .primary:
      LocalizedStringResource(
        "Primary Display",
        comment: "Launcher window placement option for the primary display."
      )
    case .mouse:
      LocalizedStringResource(
        "Display With Mouse",
        comment: "Launcher window placement option for the display containing the mouse cursor."
      )
    case .activeWindow:
      LocalizedStringResource(
        "Active Display",
        comment: "Launcher window placement option for the currently active display."
      )
    }
  }

  static var current: LauncherScreenPreference {
    guard
      let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
      let value = LauncherScreenPreference(rawValue: rawValue)
    else {
      return defaultValue
    }

    return value
  }

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

enum LauncherPreferenceKey {
  static let screenPlacement = "launcherScreenPreference"
  static let forceEnglishInputSource = "launcherForceEnglishInputSource"
}
