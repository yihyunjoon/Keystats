import AppKit
import Observation

enum WindowTileAction: String, CaseIterable {
  case leftHalf
  case rightHalf

  var commandID: String {
    switch self {
    case .leftHalf:
      return "tile-left-half"
    case .rightHalf:
      return "tile-right-half"
    }
  }

  var commandTitle: String {
    switch self {
    case .leftHalf:
      return "Tile left half"
    case .rightHalf:
      return "Tile right half"
    }
  }
}

enum WindowManagerError: Error, Equatable, LocalizedError {
  case permissionDenied
  case noFocusedWindow
  case noUsableScreen
  case applyFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return String(localized: "Accessibility permission is required.")
    case .noFocusedWindow:
      return String(localized: "No focused window.")
    case .noUsableScreen:
      return String(localized: "No usable screen found.")
    case .applyFailed:
      return String(localized: "Failed to move window.")
    }
  }
}

@Observable
@MainActor
final class WindowManagerService {
  // MARK: - Properties

  private let permissionService: AccessibilityPermissionService

  // MARK: - Initialization

  init(permissionService: AccessibilityPermissionService) {
    self.permissionService = permissionService
  }

  // MARK: - Public API

  func execute(
    _ action: WindowTileAction,
    preferredWindowElement: AXUIElement? = nil
  ) -> Result<Void, WindowManagerError> {
    permissionService.refresh()

    guard permissionService.isGranted else {
      return .failure(.permissionDenied)
    }

    let resolvedWindowElement =
      preferredWindowElement?.frame?.isNull == false
      ? preferredWindowElement
      : AXUIElement.focusedWindowElement()

    guard
      let windowElement = resolvedWindowElement,
      let focusedWindowAXFrame = windowElement.frame,
      !focusedWindowAXFrame.isNull
    else {
      return .failure(.noFocusedWindow)
    }

    let focusedWindowFrame = focusedWindowAXFrame.screenFlipped

    guard let targetScreen = screenContaining(windowFrame: focusedWindowFrame) else {
      return .failure(.noUsableScreen)
    }

    let targetVisibleFrame = targetScreen.visibleFrame
    let targetFrame = tiledFrame(for: action, in: targetVisibleFrame)
    let targetAXFrame = targetFrame.screenFlipped

    guard windowElement.setFrame(targetAXFrame) else {
      return .failure(.applyFailed)
    }

    return .success(())
  }

  // MARK: - Private

  private func tiledFrame(
    for action: WindowTileAction,
    in visibleFrame: CGRect
  ) -> CGRect {
    let halfWidth = floor(visibleFrame.width / 2.0)
    var frame = visibleFrame
    frame.size.width = halfWidth

    switch action {
    case .leftHalf:
      frame.origin.x = visibleFrame.minX
    case .rightHalf:
      frame.origin.x = visibleFrame.maxX - halfWidth
    }

    return frame
  }

  private func screenContaining(windowFrame: CGRect) -> NSScreen? {
    let screens = NSScreen.screens
    guard !screens.isEmpty else { return nil }

    if let containingScreen = screens.first(where: { $0.frame.contains(windowFrame) }) {
      return containingScreen
    }

    var bestScreen: NSScreen?
    var bestRatio: CGFloat = 0

    for screen in screens {
      let ratio = windowFrame.intersectionRatio(with: screen.frame)
      if ratio > bestRatio {
        bestRatio = ratio
        bestScreen = screen
      }
    }

    return bestScreen ?? NSScreen.main
  }
}
