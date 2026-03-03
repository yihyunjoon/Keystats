import Darwin
import Foundation

final class SkyLightBridge {
  typealias FMainConnectionID = @convention(c) () -> Int32
  typealias FSpaceCreate = @convention(c) (Int32, Int32, Int32) -> Int32
  typealias FSpaceSetAbsoluteLevel = @convention(c) (Int32, Int32, Int32) -> Int32
  typealias FShowSpaces = @convention(c) (Int32, CFArray) -> Int32
  typealias FAddWindowsAndRemoveFromSpaces = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32
  typealias FGetActiveSpace = @convention(c) (Int32) -> UInt64
  typealias FSpaceGetType = @convention(c) (Int32, UInt64) -> Int32
  typealias FManagedDisplayGetCurrentSpace = @convention(c) (Int32, CFString) -> UInt64

  private let handle: UnsafeMutableRawPointer

  private let fMainConnectionID: FMainConnectionID
  private let fSpaceCreate: FSpaceCreate
  private let fSpaceSetAbsoluteLevel: FSpaceSetAbsoluteLevel
  private let fShowSpaces: FShowSpaces
  private let fAddWindowsAndRemoveFromSpaces: FAddWindowsAndRemoveFromSpaces
  private let fGetActiveSpace: FGetActiveSpace
  private let fSpaceGetType: FSpaceGetType
  private let fManagedDisplayGetCurrentSpace: FManagedDisplayGetCurrentSpace

  init() throws {
    guard let handle = dlopen(
      "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight",
      RTLD_NOW
    ) else {
      throw CustomMenubarRuntimeError.bridgeUnavailable
    }

    self.handle = handle

    do {
      fMainConnectionID = try Self.loadSymbol(
        handle: handle,
        name: "SLSMainConnectionID",
        type: FMainConnectionID.self
      )
      fSpaceCreate = try Self.loadSymbol(
        handle: handle,
        name: "SLSSpaceCreate",
        type: FSpaceCreate.self
      )
      fSpaceSetAbsoluteLevel = try Self.loadSymbol(
        handle: handle,
        name: "SLSSpaceSetAbsoluteLevel",
        type: FSpaceSetAbsoluteLevel.self
      )
      fShowSpaces = try Self.loadSymbol(
        handle: handle,
        name: "SLSShowSpaces",
        type: FShowSpaces.self
      )
      fAddWindowsAndRemoveFromSpaces = try Self.loadSymbol(
        handle: handle,
        name: "SLSSpaceAddWindowsAndRemoveFromSpaces",
        type: FAddWindowsAndRemoveFromSpaces.self
      )
      fGetActiveSpace = try Self.loadSymbol(
        handle: handle,
        name: "SLSGetActiveSpace",
        type: FGetActiveSpace.self
      )
      fSpaceGetType = try Self.loadSymbol(
        handle: handle,
        name: "SLSSpaceGetType",
        type: FSpaceGetType.self
      )
      fManagedDisplayGetCurrentSpace = try Self.loadSymbol(
        handle: handle,
        name: "SLSManagedDisplayGetCurrentSpace",
        type: FManagedDisplayGetCurrentSpace.self
      )
    } catch {
      dlclose(handle)
      throw error
    }
  }

  deinit {
    dlclose(handle)
  }

  var mainConnectionID: Int32 {
    fMainConnectionID()
  }

  func createSpace(connectionID: Int32) -> Int32 {
    fSpaceCreate(connectionID, 1, 0)
  }

  @discardableResult
  func setAbsoluteLevel(connectionID: Int32, spaceID: Int32, level: Int32) -> Int32 {
    fSpaceSetAbsoluteLevel(connectionID, spaceID, level)
  }

  @discardableResult
  func showSpaces(connectionID: Int32, spaceIDs: [Int32]) -> Int32 {
    withInt32CFArray(values: spaceIDs) { array in
      fShowSpaces(connectionID, array)
    }
  }

  @discardableResult
  func moveWindow(connectionID: Int32, windowNumber: Int32, toSpaceID spaceID: Int32) -> Int32 {
    let wid = UInt32(bitPattern: windowNumber)
    return withUInt32CFArray(values: [wid]) { array in
      fAddWindowsAndRemoveFromSpaces(connectionID, spaceID, array, 7)
    }
  }

  func activeSpaceID(connectionID: Int32) -> UInt64 {
    fGetActiveSpace(connectionID)
  }

  func spaceType(connectionID: Int32, spaceID: UInt64) -> Int32 {
    fSpaceGetType(connectionID, spaceID)
  }

  func managedDisplayCurrentSpace(connectionID: Int32, displayUUID: CFString) -> UInt64 {
    fManagedDisplayGetCurrentSpace(connectionID, displayUUID)
  }

  private static func loadSymbol<T>(
    handle: UnsafeMutableRawPointer,
    name: String,
    type: T.Type
  ) throws -> T {
    guard let symbol = dlsym(handle, name) else {
      throw CustomMenubarRuntimeError.symbolNotFound(name)
    }

    return unsafeBitCast(symbol, to: type)
  }

  private func withInt32CFArray(
    values: [Int32],
    _ body: (CFArray) -> Int32
  ) -> Int32 {
    var numbers: [CFNumber] = []
    numbers.reserveCapacity(values.count)

    for value in values {
      var copy = value
      guard let number = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &copy) else {
        continue
      }
      numbers.append(number)
    }

    let cfArray = numbers as CFArray
    return body(cfArray)
  }

  private func withUInt32CFArray(
    values: [UInt32],
    _ body: (CFArray) -> Int32
  ) -> Int32 {
    var numbers: [CFNumber] = []
    numbers.reserveCapacity(values.count)

    for value in values {
      var copy = Int32(bitPattern: value)
      guard let number = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &copy) else {
        continue
      }
      numbers.append(number)
    }

    let cfArray = numbers as CFArray
    return body(cfArray)
  }
}
