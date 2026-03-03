import AppKit
import CoreGraphics

final class SkyLightSpaceManager {
  private enum Constants {
    static let customSpaceLevel = Int32(0)
    static let fullScreenSpaceType = Int32(4)
  }

  private let bridge: SkyLightBridge

  let connectionID: Int32
  let customSpaceID: Int32

  init() throws {
    bridge = try SkyLightBridge()

    connectionID = bridge.mainConnectionID
    customSpaceID = bridge.createSpace(connectionID: connectionID)

    _ = bridge.setAbsoluteLevel(
      connectionID: connectionID,
      spaceID: customSpaceID,
      level: Constants.customSpaceLevel
    )
    _ = bridge.showSpaces(connectionID: connectionID, spaceIDs: [customSpaceID])
  }

  func attachWindow(_ window: NSWindow) throws {
    guard window.windowNumber > 0 else {
      throw CustomMenubarRuntimeError.windowBindFailed(-1)
    }

    let result = bridge.moveWindow(
      connectionID: connectionID,
      windowNumber: Int32(window.windowNumber),
      toSpaceID: customSpaceID
    )

    guard result == 0 else {
      throw CustomMenubarRuntimeError.windowBindFailed(result)
    }
  }

  func isFullscreen(screen: NSScreen) -> Bool {
    guard
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    else {
      return false
    }

    let displayID = CGDirectDisplayID(screenNumber.uint32Value)
    guard let unmanagedDisplayUUID = CGDisplayCreateUUIDFromDisplayID(displayID) else {
      return false
    }

    let displayUUID = unmanagedDisplayUUID.takeRetainedValue()
    guard let uuidString = CFUUIDCreateString(nil, displayUUID) else {
      return false
    }

    let activeSpaceID = bridge.managedDisplayCurrentSpace(
      connectionID: connectionID,
      displayUUID: uuidString
    )
    let spaceType = bridge.spaceType(connectionID: connectionID, spaceID: activeSpaceID)
    return spaceType == Constants.fullScreenSpaceType
  }
}
