import AppKit
import Foundation
import KeyboardShortcuts

final class GlobalHotKeyService {
  // MARK: - Properties

  var onHotKeyPressed: (() -> Void)?

  // MARK: - Registration

  func configure(shortcut: KeyboardShortcuts.Shortcut?) {
    KeyboardShortcuts.setShortcut(shortcut, for: .toggleLauncher)
    registerHandlers()
  }

  // MARK: - Private

  private func registerHandlers() {
    KeyboardShortcuts.removeAllHandlers()
    KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [weak self] in
      self?.onHotKeyPressed?()
    }
  }
}

extension KeyboardShortcuts.Name {
  static let toggleLauncher = Self(
    "toggleLauncher",
    default: .init(.space, modifiers: [.command, .shift])
  )
}
