import SwiftData

@MainActor
final class AppEnvironment {
  let permissionService: InputMonitoringPermissionService
  let monitorService: KeyboardMonitorService

  init(
    permissionService: InputMonitoringPermissionService? = nil,
    monitorService: KeyboardMonitorService? = nil
  ) {
    self.permissionService =
      permissionService ?? InputMonitoringPermissionService()
    self.monitorService =
      monitorService ?? KeyboardMonitorService()
  }

  func configureMonitoring(container: ModelContainer, shouldAutoStart: Bool) {
    monitorService.configure(with: container)
    applyMonitoringPolicy(shouldAutoStart: shouldAutoStart)
  }

  func applyMonitoringPolicy(shouldAutoStart: Bool) {
    guard shouldAutoStart else {
      monitorService.stopMonitoring()
      return
    }

    guard permissionService.isGranted else { return }
    _ = monitorService.startMonitoring()
  }

  func handlePermissionChange(_ isGranted: Bool, shouldAutoStart: Bool) {
    guard shouldAutoStart else { return }
    guard isGranted else { return }
    _ = monitorService.startMonitoring()
  }
}
