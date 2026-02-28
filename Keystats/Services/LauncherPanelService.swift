import AppKit
import SwiftUI

@MainActor
final class LauncherPanelService {
  // MARK: - Properties

  private var panel: LauncherPanel?

  // MARK: - Panel Control

  func togglePanel() {
    if panel?.isVisible == true {
      hidePanel()
    } else {
      showPanel()
    }
  }

  func hidePanel() {
    panel?.orderOut(nil)
  }

  func showPanel() {
    if panel == nil {
      panel = createPanel()
    }

    guard let panel else { return }

    panel.center()
    panel.makeKeyAndOrderFront(nil)

    NotificationCenter.default.post(
      name: .launcherPanelDidOpen,
      object: nil
    )
  }

  // MARK: - Private

  private func createPanel() -> LauncherPanel {
    let contentView = LauncherInputView { [weak self] in
      self?.hidePanel()
    }

    let hostingController = NSHostingController(rootView: contentView)

    let panel = LauncherPanel(
      contentRect: NSRect(x: 0, y: 0, width: 680, height: 140),
      styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [
      .fullScreenAuxiliary,
      .transient,
      .moveToActiveSpace,
    ]
    panel.isMovableByWindowBackground = true
    panel.hidesOnDeactivate = false
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.standardWindowButton(.closeButton)?.isHidden = true
    panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
    panel.standardWindowButton(.zoomButton)?.isHidden = true
    panel.contentViewController = hostingController

    return panel
  }
}

private final class LauncherPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func resignMain() {
    super.resignMain()
    orderOut(nil)
  }
}

extension Notification.Name {
  static let launcherPanelDidOpen = Notification.Name("launcherPanelDidOpen")
}
