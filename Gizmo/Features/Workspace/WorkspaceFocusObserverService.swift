import AppKit
import ApplicationServices

@MainActor
final class WorkspaceFocusObserverService {
  var onFocusedWindowChanged: (() -> Void)?

  private let permissionService: AccessibilityPermissionService

  private var isRunning = false
  private var activeApplicationObserver: NSObjectProtocol?
  private var axObserver: AXObserver?
  private var observedPID: pid_t?
  private var didScheduleFocusChange = false

  init(permissionService: AccessibilityPermissionService) {
    self.permissionService = permissionService
  }

  func start() {
    guard !isRunning else { return }

    isRunning = true
    observeActiveApplicationIfNeeded()
    refreshObserverForFrontmostApplication()
    scheduleFocusChange()
  }

  func stop() {
    guard isRunning else { return }

    isRunning = false
    removeActiveApplicationObserver()
    removeAXObserver()
    didScheduleFocusChange = false
  }

  private func observeActiveApplicationIfNeeded() {
    guard activeApplicationObserver == nil else { return }

    activeApplicationObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      let processIdentifier =
        (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?
        .processIdentifier

      Task { @MainActor [weak self] in
        self?.handleActiveApplicationDidChange(processIdentifier)
      }
    }
  }

  private func removeActiveApplicationObserver() {
    if let activeApplicationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(activeApplicationObserver)
      self.activeApplicationObserver = nil
    }
  }

  private func handleActiveApplicationDidChange(_ processIdentifier: pid_t?) {
    guard isRunning else { return }

    refreshObserver(for: processIdentifier)
    scheduleFocusChange()
  }

  private func refreshObserverForFrontmostApplication() {
    refreshObserver(for: NSWorkspace.shared.frontmostApplication?.processIdentifier)
  }

  private func refreshObserver(for pid: pid_t?) {
    permissionService.refresh()

    guard permissionService.isGranted else {
      removeAXObserver()
      return
    }

    guard let pid else {
      removeAXObserver()
      return
    }

    guard pid != ProcessInfo.processInfo.processIdentifier else {
      removeAXObserver()
      return
    }

    guard observedPID != pid else { return }

    removeAXObserver()

    var observer: AXObserver?
    let createResult = AXObserverCreate(
      pid,
      { _, _, _, refcon in
        guard let refcon else { return }

        let service = Unmanaged<WorkspaceFocusObserverService>
          .fromOpaque(refcon)
          .takeUnretainedValue()

        Task { @MainActor in
          service.handleAXWindowFocusDidChange()
        }
      },
      &observer
    )

    guard createResult == .success, let observer else { return }

    let appElement = AXUIElementCreateApplication(pid)
    let observerContext = Unmanaged.passUnretained(self).toOpaque()

    let focusedWindowResult = AXObserverAddNotification(
      observer,
      appElement,
      kAXFocusedWindowChangedNotification as CFString,
      observerContext
    )

    let mainWindowResult = AXObserverAddNotification(
      observer,
      appElement,
      kAXMainWindowChangedNotification as CFString,
      observerContext
    )

    let didRegisterNotification =
      Self.isNotificationRegistered(focusedWindowResult)
      || Self.isNotificationRegistered(mainWindowResult)

    guard didRegisterNotification else { return }

    CFRunLoopAddSource(
      CFRunLoopGetMain(),
      AXObserverGetRunLoopSource(observer),
      .defaultMode
    )

    axObserver = observer
    observedPID = pid
  }

  private func handleAXWindowFocusDidChange() {
    guard isRunning else { return }
    scheduleFocusChange()
  }

  private func removeAXObserver() {
    guard let axObserver else {
      observedPID = nil
      return
    }

    CFRunLoopRemoveSource(
      CFRunLoopGetMain(),
      AXObserverGetRunLoopSource(axObserver),
      .defaultMode
    )

    self.axObserver = nil
    observedPID = nil
  }

  private func scheduleFocusChange() {
    guard !didScheduleFocusChange else { return }

    didScheduleFocusChange = true
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.didScheduleFocusChange = false
      guard self.isRunning else { return }

      self.onFocusedWindowChanged?()
    }
  }

  private static func isNotificationRegistered(_ result: AXError) -> Bool {
    result == .success || result == .notificationAlreadyRegistered
  }
}
