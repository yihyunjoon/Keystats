import Foundation

struct LauncherCommandUsage: Codable, Equatable {
  var executionCount: Int
  var lastExecutedAt: Date?

  static let empty = LauncherCommandUsage(
    executionCount: 0,
    lastExecutedAt: nil
  )
}

final class LauncherUsageStore {
  private enum Storage {
    static let key = "launcher.commandUsage.v1"
  }

  private let userDefaults: UserDefaults
  private let now: () -> Date
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  private var usageMap: [String: LauncherCommandUsage]

  init(
    userDefaults: UserDefaults = .standard,
    now: @escaping () -> Date = Date.init
  ) {
    self.userDefaults = userDefaults
    self.now = now
    self.usageMap = [:]
    usageMap = loadUsageMap()
  }

  func recordExecution(commandID: String) {
    guard !commandID.isEmpty else { return }

    var usage = usageMap[commandID] ?? .empty
    usage.executionCount += 1
    usage.lastExecutedAt = now()
    usageMap[commandID] = usage

    persist()
  }

  func usage(for commandID: String) -> LauncherCommandUsage {
    usageMap[commandID] ?? .empty
  }

  func usageScore(for commandID: String, now nowDate: Date = Date()) -> Double {
    usageScore(for: usage(for: commandID), now: nowDate)
  }

  func sortedCommandsForEmptyQuery(_ commands: [LauncherCommand]) -> [LauncherCommand] {
    let nowDate = now()

    return commands.enumerated()
      .sorted { lhs, rhs in
        let lhsUsage = usage(for: lhs.element.id)
        let rhsUsage = usage(for: rhs.element.id)

        let lhsScore = usageScore(for: lhsUsage, now: nowDate)
        let rhsScore = usageScore(for: rhsUsage, now: nowDate)

        if lhsScore != rhsScore {
          return lhsScore > rhsScore
        }

        if lhsUsage.lastExecutedAt != rhsUsage.lastExecutedAt {
          return (lhsUsage.lastExecutedAt ?? .distantPast) > (rhsUsage.lastExecutedAt ?? .distantPast)
        }

        if lhsUsage.executionCount != rhsUsage.executionCount {
          return lhsUsage.executionCount > rhsUsage.executionCount
        }

        return lhs.offset < rhs.offset
      }
      .map(\.element)
  }

  private func usageScore(for usage: LauncherCommandUsage, now nowDate: Date) -> Double {
    guard usage.executionCount > 0 else { return 0 }

    let frequencyScore = log2(Double(usage.executionCount) + 1.0) * 100.0

    let recencyScore: Double
    if let lastExecutedAt = usage.lastExecutedAt {
      let age = max(0, nowDate.timeIntervalSince(lastExecutedAt))
      let freshnessWindow: TimeInterval = 60 * 60 * 24 * 7
      let freshness = max(0, 1.0 - min(age, freshnessWindow) / freshnessWindow)
      recencyScore = freshness * 100.0
    } else {
      recencyScore = 0
    }

    return frequencyScore + recencyScore
  }

  private func loadUsageMap() -> [String: LauncherCommandUsage] {
    guard let data = userDefaults.data(forKey: Storage.key) else {
      return [:]
    }

    do {
      return try decoder.decode([String: LauncherCommandUsage].self, from: data)
    } catch {
      userDefaults.removeObject(forKey: Storage.key)
      return [:]
    }
  }

  private func persist() {
    do {
      let data = try encoder.encode(usageMap)
      userDefaults.set(data, forKey: Storage.key)
    } catch {
      assertionFailure("Failed to persist launcher usage map: \(error)")
    }
  }
}
