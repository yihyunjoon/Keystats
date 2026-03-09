import Observation
import ServiceManagement

@Observable
@MainActor
final class LaunchAtLoginService {
  // MARK: - Properties

  private(set) var isEnabled: Bool = false
  private(set) var requiresApproval: Bool = false
  private(set) var isUpdating: Bool = false
  private(set) var lastError: String?

  @ObservationIgnored
  private let service: SMAppService

  // MARK: - Initialization

  init(service: SMAppService = .mainApp) {
    self.service = service
    refresh()
  }

  // MARK: - Public API

  func refresh(clearError: Bool = true) {
    if clearError {
      lastError = nil
    }

    switch service.status {
    case .enabled:
      isEnabled = true
      requiresApproval = false
    case .requiresApproval:
      isEnabled = true
      requiresApproval = true
    case .notRegistered:
      isEnabled = false
      requiresApproval = false
    case .notFound:
      isEnabled = false
      requiresApproval = false
      lastError = String(localized: "Gizmo couldn't verify the current login item status.")
    @unknown default:
      isEnabled = false
      requiresApproval = false
      lastError = String(localized: "Gizmo couldn't verify the current login item status.")
    }
  }

  func setEnabled(_ shouldEnable: Bool) {
    isUpdating = true
    defer { isUpdating = false }

    do {
      if shouldEnable {
        try service.register()
      } else {
        try service.unregister()
      }
      refresh()
    } catch {
      refresh(clearError: false)
      lastError = error.localizedDescription
    }
  }

  func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }

  var statusDescription: String {
    if requiresApproval {
      return String(
        localized:
          "Approve Gizmo in System Settings > General > Login Items to finish enabling launch at login."
      )
    }

    if isEnabled {
      return String(localized: "Gizmo will launch automatically when you sign in.")
    }

    return String(localized: "Gizmo won't launch automatically when you sign in.")
  }
}
