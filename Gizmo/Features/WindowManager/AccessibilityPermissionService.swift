import AppKit
import ApplicationServices
import Observation

@Observable
@MainActor
final class AccessibilityPermissionService {
  // MARK: - Properties

  private(set) var isGranted: Bool = false
  private var pollingTimer: Timer?

  // MARK: - Initialization

  init() {
    refresh()
  }

  // MARK: - Public API

  func refresh() {
    isGranted = AXIsProcessTrusted()
  }

  func requestPermissionPrompt() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
      as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
    refresh()
    startPollingForPermission()
  }

  func openSystemSettings() {
    guard
      let url = URL(
        string:
          "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
      )
    else {
      return
    }

    NSWorkspace.shared.open(url)
  }

  // MARK: - Private

  private func startPollingForPermission() {
    pollingTimer?.invalidate()

    pollingTimer = Timer.scheduledTimer(
      withTimeInterval: 1.0,
      repeats: true
    ) { [weak self] _ in
      guard let self else { return }
      Task { @MainActor in
        self.refresh()

        if self.isGranted {
          self.pollingTimer?.invalidate()
          self.pollingTimer = nil
        }
      }
    }
  }
}
