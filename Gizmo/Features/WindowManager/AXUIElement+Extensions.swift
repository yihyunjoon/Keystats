import AppKit
import ApplicationServices

extension AXValue {
  fileprivate func decodedValue<T>(as type: T.Type) -> T? {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    defer { pointer.deallocate() }

    let success = AXValueGetValue(self, AXValueGetType(self), pointer)
    return success ? pointer.pointee : nil
  }

  fileprivate static func makeValue<T>(_ value: T, type: AXValueType) -> AXValue? {
    var value = value
    return withUnsafePointer(to: &value) { pointer in
      AXValueCreate(type, pointer)
    }
  }
}

extension AXUIElement {
  static let systemWide = AXUIElementCreateSystemWide()

  fileprivate func attributeValue(_ attribute: CFString) -> AnyObject? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(self, attribute, &value)
    guard result == .success else { return nil }
    return value
  }

  fileprivate func setAttributeValue(
    _ attribute: CFString,
    value: CFTypeRef
  ) -> Bool {
    AXUIElementSetAttributeValue(self, attribute, value) == .success
  }

  fileprivate func wrappedValue<T>(
    _ attribute: CFString,
    as type: T.Type
  ) -> T? {
    guard let rawValue = attributeValue(attribute) else { return nil }
    guard CFGetTypeID(rawValue) == AXValueGetTypeID() else { return nil }
    return (rawValue as! AXValue).decodedValue(as: type)
  }

  fileprivate func setWrappedValue<T>(
    _ attribute: CFString,
    value: T,
    type: AXValueType
  ) -> Bool {
    guard let axValue = AXValue.makeValue(value, type: type) else { return false }
    return setAttributeValue(attribute, value: axValue)
  }

  var position: CGPoint? {
    wrappedValue(kAXPositionAttribute as CFString, as: CGPoint.self)
  }

  var size: CGSize? {
    wrappedValue(kAXSizeAttribute as CFString, as: CGSize.self)
  }

  var frame: CGRect? {
    guard let position, let size else { return nil }
    return CGRect(origin: position, size: size)
  }

  @discardableResult
  func setFrame(_ frame: CGRect) -> Bool {
    let didSetSizeInitially = setWrappedValue(
      kAXSizeAttribute as CFString,
      value: frame.size,
      type: .cgSize
    )
    let didSetPosition = setWrappedValue(
      kAXPositionAttribute as CFString,
      value: frame.origin,
      type: .cgPoint
    )
    let didSetSizeFinally = setWrappedValue(
      kAXSizeAttribute as CFString,
      value: frame.size,
      type: .cgSize
    )

    return didSetSizeInitially && didSetPosition && didSetSizeFinally
  }

  static func focusedWindowElement() -> AXUIElement? {
    guard
      let focusedAppValue = systemWide.attributeValue(
        kAXFocusedApplicationAttribute as CFString
      ),
      CFGetTypeID(focusedAppValue) == AXUIElementGetTypeID()
    else {
      return nil
    }

    let focusedApp = focusedAppValue as! AXUIElement

    if
      let focusedWindowValue = focusedApp.attributeValue(
        kAXFocusedWindowAttribute as CFString
      ),
      CFGetTypeID(focusedWindowValue) == AXUIElementGetTypeID()
    {
      return (focusedWindowValue as! AXUIElement)
    }

    guard
      let windowsValue = focusedApp.attributeValue(kAXWindowsAttribute as CFString),
      let windows = windowsValue as? [AXUIElement]
    else {
      return nil
    }

    return windows.first
  }
}
