import AppKit
import CoreGraphics

final class CustomMenubarWindow: NSWindow {
  static let renderLevel = NSWindow.Level(
    rawValue: Int(CGWindowLevelForKey(.backstopMenu))
  )

  static func frame(for screen: NSScreen, height: CGFloat, position: CustomMenubarPosition)
    -> NSRect {
    let y: CGFloat

    switch position {
    case .top:
      y = screen.frame.maxY - height
    case .bottom:
      y = screen.visibleFrame.minY
    }

    return NSRect(
      x: screen.frame.minX,
      y: y,
      width: screen.frame.width,
      height: height
    )
  }

  init(screen: NSScreen, config: CustomMenubarConfig) {
    super.init(
      contentRect: Self.frame(
        for: screen,
        height: CGFloat(config.height),
        position: config.position
      ),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    ignoresMouseEvents = false
    acceptsMouseMovedEvents = true
    isMovable = false
    isMovableByWindowBackground = false
    collectionBehavior = [
      .canJoinAllSpaces,
      .stationary,
      .fullScreenAuxiliary,
      .ignoresCycle,
    ]
    level = Self.renderLevel
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}
