import AppKit
import IOKit.hid
import Observation

@Observable
@MainActor
final class InputMonitoringPermissionService {
  // MARK: - Properties

  private(set) var isGranted: Bool = false
  private var pollingTimer: Timer?

  // MARK: - Initialization

  init() {
    checkPermission()
  }

  // MARK: - Permission Check

  func checkPermission() {
    let status = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
    isGranted = (status == kIOHIDAccessTypeGranted)
  }

  // MARK: - Permission Request

  func requestPermission() {
    let granted = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)

    if granted {
      isGranted = true
    } else {
      startPollingForPermission()
    }
  }

  // MARK: - Open System Settings

  func openSystemSettings() {
    let url = URL(
      string:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
    )!
    NSWorkspace.shared.open(url)
  }

  // MARK: - Polling

  func startPollingForPermission() {
    pollingTimer?.invalidate()

    pollingTimer = Timer.scheduledTimer(
      withTimeInterval: 1.0,
      repeats: true
    ) { [weak self] _ in
      guard let self else { return }
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.checkPermission()
        if self.isGranted {
          self.stopPolling()
        }
      }
    }
  }

  func stopPolling() {
    pollingTimer?.invalidate()
    pollingTimer = nil
  }
}
