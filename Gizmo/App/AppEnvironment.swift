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

  func configureMonitoring(context: ModelContext) {
    monitorService.configure(with: context)

    if permissionService.isGranted {
      _ = monitorService.startMonitoring()
    }
  }

  func handlePermissionChange(_ isGranted: Bool) {
    guard isGranted else { return }
    _ = monitorService.startMonitoring()
  }
}
