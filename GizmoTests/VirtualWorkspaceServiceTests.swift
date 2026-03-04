import ApplicationServices
import CoreGraphics
import XCTest
@testable import Gizmo

@MainActor
final class VirtualWorkspaceServiceTests: XCTestCase {
  func testRestoreFromPersistedFramesDoesNotMoveActiveWorkspaceWindowOnStartup() {
    let activeKey = "axwn:100"
    let inactiveKey = "axwn:200"

    let driver = MockWorkspaceWindowDriver(
      manageableWindows: [
        makeWindow(key: activeKey),
        makeWindow(key: inactiveKey),
      ],
      frames: [
        activeKey: CGRect(x: 10, y: 10, width: 800, height: 600),
        inactiveKey: CGRect(x: 30, y: 40, width: 700, height: 500),
      ],
      visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )
    let store = MockWorkspaceMappingStore(
      loadSnapshot: WorkspaceMappingSnapshot(
        workspaceWindows: [
          "1": [activeKey],
          "2": [inactiveKey],
        ],
        savedFrames: [
          activeKey: PersistedWindowFrame(x: 100, y: 120, width: 900, height: 700),
          inactiveKey: PersistedWindowFrame(x: 220, y: 240, width: 880, height: 660),
        ]
      )
    )

    _ = VirtualWorkspaceService(
      driver: driver,
      initialConfig: makeWorkspaceConfig(),
      workspaceMappingStore: store
    )

    XCTAssertFalse(driver.setFrameCalls.contains(where: { $0.windowKey == activeKey }))
  }

  func testSwitchToInactiveWorkspaceRestoresPersistedFrame() {
    let activeKey = "axwn:100"
    let inactiveKey = "axwn:200"
    let inactivePersistedFrame = CGRect(x: 220, y: 240, width: 880, height: 660)

    let driver = MockWorkspaceWindowDriver(
      manageableWindows: [
        makeWindow(key: activeKey),
        makeWindow(key: inactiveKey),
      ],
      frames: [
        activeKey: CGRect(x: 10, y: 10, width: 800, height: 600),
        inactiveKey: CGRect(x: 30, y: 40, width: 700, height: 500),
      ],
      visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )
    let store = MockWorkspaceMappingStore(
      loadSnapshot: WorkspaceMappingSnapshot(
        workspaceWindows: [
          "1": [activeKey],
          "2": [inactiveKey],
        ],
        savedFrames: [
          inactiveKey: PersistedWindowFrame(rect: inactivePersistedFrame)
        ]
      )
    )

    let service = VirtualWorkspaceService(
      driver: driver,
      initialConfig: makeWorkspaceConfig(),
      workspaceMappingStore: store
    )

    driver.resetRecordedCalls()
    _ = service.focusWorkspace("2")

    XCTAssertTrue(
      driver.setFrameCalls.contains(where: {
        $0.windowKey == inactiveKey && $0.frame == inactivePersistedFrame
      })
    )
  }

  func testPersistsSnapshotWhenOnlySavedFramesChanged() throws {
    let key1 = "axwn:100"
    let key2 = "axwn:200"

    let window1 = makeWindow(key: key1)
    let window2 = makeWindow(key: key2)

    let driver = MockWorkspaceWindowDriver(
      manageableWindows: [window1, window2],
      frames: [
        key1: CGRect(x: 0, y: 0, width: 700, height: 500),
        key2: CGRect(x: 200, y: 200, width: 600, height: 400),
      ],
      visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )
    let store = MockWorkspaceMappingStore()

    let service = VirtualWorkspaceService(
      driver: driver,
      initialConfig: makeWorkspaceConfig(),
      workspaceMappingStore: store
    )

    driver.focusedWindow = window2
    _ = service.moveFocusedWindowToWorkspace("2")

    let workspace1KeysBefore = Set(service.managedWindowKeys(in: "1"))
    let workspace2KeysBefore = Set(service.managedWindowKeys(in: "2"))

    store.savedSnapshots.removeAll()

    _ = service.focusWorkspace("2")

    let persistedSnapshot = try XCTUnwrap(store.savedSnapshots.last)

    XCTAssertEqual(Set(persistedSnapshot.workspaceWindows["1", default: []]), workspace1KeysBefore)
    XCTAssertEqual(Set(persistedSnapshot.workspaceWindows["2", default: []]), workspace2KeysBefore)
    XCTAssertEqual(Set(persistedSnapshot.savedFrames.keys), [key1])
  }

  func testRestoreAllWindowsClearsSavedFramesAndPersistsSnapshot() throws {
    let key1 = "axwn:100"
    let key2 = "axwn:200"

    let window1 = makeWindow(key: key1)
    let window2 = makeWindow(key: key2)

    let driver = MockWorkspaceWindowDriver(
      manageableWindows: [window1, window2],
      frames: [
        key1: CGRect(x: 0, y: 0, width: 700, height: 500),
        key2: CGRect(x: 200, y: 200, width: 600, height: 400),
      ],
      visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080)
    )
    let store = MockWorkspaceMappingStore()

    let service = VirtualWorkspaceService(
      driver: driver,
      initialConfig: makeWorkspaceConfig(),
      workspaceMappingStore: store
    )

    driver.focusedWindow = window2
    _ = service.moveFocusedWindowToWorkspace("2")

    store.savedSnapshots.removeAll()

    service.restoreAllWindows()

    XCTAssertTrue(service.debugSnapshot().hiddenWindowKeys.isEmpty)

    let persistedSnapshot = try XCTUnwrap(store.savedSnapshots.last)
    XCTAssertTrue(persistedSnapshot.savedFrames.isEmpty)
  }

  private func makeWorkspaceConfig() -> WorkspaceConfig {
    WorkspaceConfig(
      enabled: true,
      names: ["1", "2"],
      hideStrategy: .cornerOffscreen
    )
  }

  private func makeWindow(key: WindowKey) -> ManagedWindowRef {
    ManagedWindowRef(
      key: key,
      element: nil,
      appName: "Test App",
      title: key
    )
  }
}

@MainActor
private final class MockWorkspaceWindowDriver: WorkspaceWindowDriver {
  struct SetFrameCall {
    let windowKey: WindowKey
    let frame: CGRect
  }

  var accessibilityGranted = true
  var focusedWindow: ManagedWindowRef?
  var manageableWindows: [ManagedWindowRef]
  var frames: [WindowKey: CGRect]
  var visibleFrame: CGRect?

  private(set) var setFrameCalls: [SetFrameCall] = []

  init(
    manageableWindows: [ManagedWindowRef],
    frames: [WindowKey: CGRect],
    visibleFrame: CGRect?
  ) {
    self.manageableWindows = manageableWindows
    self.frames = frames
    self.visibleFrame = visibleFrame
    self.focusedWindow = manageableWindows.first
  }

  func isAccessibilityGranted() -> Bool {
    accessibilityGranted
  }

  func resolveFocusedWindow(preferredWindow: AXUIElement?) -> ManagedWindowRef? {
    focusedWindow
  }

  func allManageableWindows() -> [ManagedWindowRef] {
    manageableWindows
  }

  func frame(for window: ManagedWindowRef) -> CGRect? {
    frames[window.key]
  }

  func setFrame(_ frame: CGRect, for window: ManagedWindowRef) -> Bool {
    setFrameCalls.append(SetFrameCall(windowKey: window.key, frame: frame))
    frames[window.key] = frame
    return true
  }

  func focus(_ window: ManagedWindowRef) -> Bool {
    true
  }

  func isWindowAlive(_ window: ManagedWindowRef) -> Bool {
    frames[window.key] != nil
  }

  func singleMonitorVisibleFrame() -> CGRect? {
    visibleFrame
  }

  func resetRecordedCalls() {
    setFrameCalls.removeAll()
  }
}

private final class MockWorkspaceMappingStore: WorkspaceMappingStore {
  var loadSnapshot: WorkspaceMappingSnapshot?
  var savedSnapshots: [WorkspaceMappingSnapshot] = []

  init(loadSnapshot: WorkspaceMappingSnapshot? = nil) {
    self.loadSnapshot = loadSnapshot
  }

  func load() -> WorkspaceMappingSnapshot? {
    loadSnapshot
  }

  func save(_ snapshot: WorkspaceMappingSnapshot) {
    savedSnapshots.append(snapshot)
    loadSnapshot = snapshot
  }
}
