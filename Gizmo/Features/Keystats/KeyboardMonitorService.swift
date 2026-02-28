import Cocoa
import Observation
import SwiftData

@Observable
@MainActor
final class KeyboardMonitorService {
  // MARK: - Properties

  private static let batchFlushIntervalNanoseconds: UInt64 = 300_000_000
  private static let maxPendingPressesBeforeFlush = 30

  private(set) var isMonitoring: Bool = false

  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var persistenceActor: KeyPressPersistenceActor?
  private var pendingCounts: [Int: Int] = [:]
  private var pendingPresses = 0
  private var flushTask: Task<Void, Never>?
  private var flushInFlightTask: Task<Void, Never>?

  // Singleton for C callback access
  private static var shared: KeyboardMonitorService?

  // MARK: - Initialization

  init() {
    KeyboardMonitorService.shared = self
  }

  // MARK: - Configuration

  func configure(with modelContainer: ModelContainer) {
    persistenceActor = KeyPressPersistenceActor(container: modelContainer)
  }

  // MARK: - Monitoring Control

  func startMonitoring() -> Bool {
    guard !isMonitoring else { return true }
    guard persistenceActor != nil else { return false }

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

    flushTask?.cancel()
    flushTask = nil
    flushPendingCounts()

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
    pendingCounts[keyCode, default: 0] += 1
    pendingPresses += 1

    if pendingPresses >= Self.maxPendingPressesBeforeFlush {
      flushTask?.cancel()
      flushTask = nil
      flushPendingCounts()
      return
    }

    scheduleFlushIfNeeded()
  }

  private func scheduleFlushIfNeeded() {
    guard flushTask == nil else { return }

    flushTask = Task { [weak self] in
      do {
        try await Task.sleep(
          nanoseconds: Self.batchFlushIntervalNanoseconds
        )
      } catch {
        return
      }

      await self?.flushPendingCounts()
    }
  }

  private func flushPendingCounts() {
    guard flushInFlightTask == nil else { return }
    guard let persistenceActor else { return }
    guard !pendingCounts.isEmpty else { return }

    let batchedCounts = pendingCounts
    let batchedPayload = batchedCounts.map { keyCode, delta in
      (
        keyCode: keyCode,
        keyName: KeyCodeMapping.name(for: keyCode),
        delta: delta
      )
    }
    pendingCounts.removeAll(keepingCapacity: true)
    pendingPresses = 0
    flushTask = nil

    flushInFlightTask = Task { [weak self, persistenceActor] in
      do {
        try await persistenceActor.flush(batchedPayload)
        await self?.handleFlushSuccess()
      } catch {
        await self?.handleFlushFailure(error, batchedCounts: batchedCounts)
      }
    }
  }

  private func handleFlushSuccess() {
    flushInFlightTask = nil

    guard !pendingCounts.isEmpty else { return }

    if pendingPresses >= Self.maxPendingPressesBeforeFlush {
      flushPendingCounts()
    } else {
      scheduleFlushIfNeeded()
    }
  }

  private func handleFlushFailure(
    _ error: Error,
    batchedCounts: [Int: Int]
  ) {
    print("Failed to flush key presses: \(error)")

    flushInFlightTask = nil
    for (keyCode, delta) in batchedCounts {
      pendingCounts[keyCode, default: 0] += delta
      pendingPresses += delta
    }
    scheduleFlushIfNeeded()
  }
}
