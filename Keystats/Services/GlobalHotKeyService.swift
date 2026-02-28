import AppKit
import Foundation
import KeyboardShortcuts

final class GlobalHotKeyService {
  // MARK: - Properties

  var onHotKeyPressed: (() -> Void)?
  private var isConfigured = false

  // MARK: - Registration

  func configure() {
    guard !isConfigured else { return }

    KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [weak self] in
      self?.onHotKeyPressed?()
    }

    isConfigured = true
  }
}

extension KeyboardShortcuts.Name {
  static let toggleLauncher = Self(
    "toggleLauncher",
    default: .init(.space, modifiers: [.command, .shift])
  )
}
