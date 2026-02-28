import Cocoa
import Observation
import SwiftData

@Observable
@MainActor
final class KeyboardMonitorService {
  // MARK: - Properties

  private(set) var isMonitoring: Bool = false

  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var modelContext: ModelContext?

  // Singleton for C callback access
  private static var shared: KeyboardMonitorService?

  // MARK: - Initialization

  init() {
    KeyboardMonitorService.shared = self
  }

  // MARK: - Configuration

  func configure(with modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  // MARK: - Monitoring Control

  func startMonitoring() -> Bool {
    guard !isMonitoring else { return true }
    guard modelContext != nil else { return false }

    let eventMask = (1 << CGEventType.keyDown.rawValue)

    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: CGEventMask(eventMask),
        callback: Self.eventCallback,
        userInfo: nil
      )
    else {
      return false
    }

    eventTap = tap
    runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault,
      tap,
      0
    )

    if let source = runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

    CGEvent.tapEnable(tap: tap, enable: true)
    isMonitoring = true

    return true
  }

  func stopMonitoring() {
    guard isMonitoring else { return }

    if let tap = eventTap {
      CGEvent.tapEnable(tap: tap, enable: false)
    }

    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }

    eventTap = nil
    runLoopSource = nil
    isMonitoring = false
  }

  // MARK: - CGEvent Callback

  private static let eventCallback: CGEventTapCallBack = {
    _,
    type,
    event,
    _ in
    guard type == .keyDown else {
      return Unmanaged.passRetained(event)
    }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    Task { @MainActor in
      shared?.recordKeyPress(keyCode: Int(keyCode))
    }

    return Unmanaged.passRetained(event)
  }

  // MARK: - Record Key Press

  private func recordKeyPress(keyCode: Int) {
    guard let context = modelContext else { return }

    let keyName = KeyCodeMapping.name(for: keyCode)

    let descriptor = FetchDescriptor<KeyPressRecord>(
      predicate: #Predicate { $0.keyCode == keyCode }
    )

    do {
      let existingRecords = try context.fetch(descriptor)

      if let record = existingRecords.first {
        record.incrementCount()
      } else {
        let newRecord = KeyPressRecord(
          keyCode: keyCode,
          keyName: keyName
        )
        context.insert(newRecord)
      }

      try context.save()
    } catch {
      print("Failed to record key press: \(error)")
    }
  }
}
