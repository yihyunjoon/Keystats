import Foundation

struct LauncherMatchSortKey: Equatable {
  let matchScore: Int
  let usageScore: Double
  let lastExecutedAt: Date?
  let executionCount: Int
  let originalIndex: Int
}

struct LauncherMatchResult: Equatable {
  let command: LauncherCommand
  let matchScore: Int
  let usageScore: Double
  let sortKey: LauncherMatchSortKey
}

struct LauncherFuzzyMatcher {
  private struct SearchField {
    let value: String
    let weight: Double
  }

  private enum FieldWeight {
    static let title = 1.0
    static let keyword = 0.75
    static let commandID = 0.55
  }

  private enum Score {
    static let matchedCharacter = 24
    static let prefixBonus = 120
    static let wordBoundaryFirstBonus = 80
    static let wordBoundaryBonus = 40
    static let consecutiveBonus = 48
    static let consecutiveStreakBonus = 8
    static let gapPenalty = 6
    static let lateStartPenalty = 3
    static let lengthPenalty = 1
  }

  func rank(
    commands: [LauncherCommand],
    query: String,
    usageStore: LauncherUsageStore
  ) -> [LauncherMatchResult] {
    let tokens = tokenize(query)

    guard !tokens.isEmpty else {
      return rankForEmptyQuery(
        commands: commands,
        usageStore: usageStore
      )
    }

    let nowDate = Date()
    let matches: [LauncherMatchResult] = commands.enumerated().compactMap { index, command in
      guard let matchScore = score(command: command, tokens: tokens) else {
        return nil
      }

      let usage = usageStore.usage(for: command.id)
      let usageScore = usageStore.usageScore(for: command.id, now: nowDate)

      return LauncherMatchResult(
        command: command,
        matchScore: matchScore,
        usageScore: usageScore,
        sortKey: LauncherMatchSortKey(
          matchScore: matchScore,
          usageScore: usageScore,
          lastExecutedAt: usage.lastExecutedAt,
          executionCount: usage.executionCount,
          originalIndex: index
        )
      )
    }

    return matches.sorted(by: shouldRankLeftBeforeRight)
  }

  private func rankForEmptyQuery(
    commands: [LauncherCommand],
    usageStore: LauncherUsageStore
  ) -> [LauncherMatchResult] {
    let indexedCommands = Dictionary(
      uniqueKeysWithValues: commands.enumerated().map { ($0.element.id, $0.offset) }
    )
    let sortedCommands = usageStore.sortedCommandsForEmptyQuery(commands)
    let nowDate = Date()

    return sortedCommands.map { command in
      let usage = usageStore.usage(for: command.id)
      let usageScore = usageStore.usageScore(for: command.id, now: nowDate)

      return LauncherMatchResult(
        command: command,
        matchScore: 0,
        usageScore: usageScore,
        sortKey: LauncherMatchSortKey(
          matchScore: 0,
          usageScore: usageScore,
          lastExecutedAt: usage.lastExecutedAt,
          executionCount: usage.executionCount,
          originalIndex: indexedCommands[command.id] ?? .max
        )
      )
    }
  }

  private func score(command: LauncherCommand, tokens: [String]) -> Int? {
    let fields = searchableFields(for: command)
    var totalScore = 0

    for token in tokens {
      var bestTokenScore: Int?

      for field in fields {
        guard let rawScore = subsequenceScore(token: token, in: field.value) else {
          continue
        }

        let weightedScore = Int((Double(rawScore) * field.weight).rounded())
        if let currentBestTokenScore = bestTokenScore {
          if weightedScore > currentBestTokenScore {
            bestTokenScore = weightedScore
          }
        } else {
          bestTokenScore = weightedScore
        }
      }

      guard let bestTokenScore else {
        return nil
      }

      totalScore += bestTokenScore
    }

    return totalScore
  }

  private func searchableFields(for command: LauncherCommand) -> [SearchField] {
    var fields = [SearchField(
      value: normalize(command.title),
      weight: FieldWeight.title
    )]

    fields.append(contentsOf: command.keywords.map {
      SearchField(value: normalize($0), weight: FieldWeight.keyword)
    })

    fields.append(
      SearchField(
        value: normalize(command.id),
        weight: FieldWeight.commandID
      )
    )

    return fields.filter { !$0.value.isEmpty }
  }

  private func subsequenceScore(token: String, in candidate: String) -> Int? {
    guard !token.isEmpty, !candidate.isEmpty else { return nil }

    let tokenCharacters = Array(token)
    let candidateCharacters = Array(candidate)

    var positions: [Int] = []
    var cursor = 0

    for character in tokenCharacters {
      var foundIndex: Int?

      while cursor < candidateCharacters.count {
        if candidateCharacters[cursor] == character {
          foundIndex = cursor
          cursor += 1
          break
        }
        cursor += 1
      }

      guard let foundIndex else {
        return nil
      }

      positions.append(foundIndex)
    }

    var score = tokenCharacters.count * Score.matchedCharacter

    if let first = positions.first {
      if first == 0 {
        score += Score.prefixBonus
      }
      score -= first * Score.lateStartPenalty
    }

    var totalGap = 0
    var consecutiveStreak = 0

    for index in positions.indices {
      let position = positions[index]

      if isWordBoundary(at: position, in: candidateCharacters) {
        score += index == 0 ? Score.wordBoundaryFirstBonus : Score.wordBoundaryBonus
      }

      guard index > 0 else { continue }

      let previous = positions[index - 1]
      let gap = max(0, position - previous - 1)
      totalGap += gap

      if gap == 0 {
        consecutiveStreak += 1
        score += Score.consecutiveBonus + (consecutiveStreak * Score.consecutiveStreakBonus)
      } else {
        consecutiveStreak = 0
      }
    }

    score -= totalGap * Score.gapPenalty
    score -= max(0, candidateCharacters.count - tokenCharacters.count) * Score.lengthPenalty

    return score
  }

  private func shouldRankLeftBeforeRight(
    _ lhs: LauncherMatchResult,
    _ rhs: LauncherMatchResult
  ) -> Bool {
    if lhs.sortKey.matchScore != rhs.sortKey.matchScore {
      return lhs.sortKey.matchScore > rhs.sortKey.matchScore
    }

    if lhs.sortKey.usageScore != rhs.sortKey.usageScore {
      return lhs.sortKey.usageScore > rhs.sortKey.usageScore
    }

    if lhs.sortKey.lastExecutedAt != rhs.sortKey.lastExecutedAt {
      return (lhs.sortKey.lastExecutedAt ?? .distantPast)
        > (rhs.sortKey.lastExecutedAt ?? .distantPast)
    }

    if lhs.sortKey.executionCount != rhs.sortKey.executionCount {
      return lhs.sortKey.executionCount > rhs.sortKey.executionCount
    }

    return lhs.sortKey.originalIndex < rhs.sortKey.originalIndex
  }

  private func tokenize(_ query: String) -> [String] {
    normalize(query)
      .split(whereSeparator: \.isWhitespace)
      .map(String.init)
      .filter { !$0.isEmpty }
  }

  private func normalize(_ text: String) -> String {
    text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(
        options: [.diacriticInsensitive, .widthInsensitive],
        locale: .current
      )
      .lowercased()
  }

  private func isWordBoundary(
    at index: Int,
    in characters: [Character]
  ) -> Bool {
    guard index > 0 else { return true }

    let previous = characters[index - 1]
    return previous == " " || previous == "-" || previous == "_" || previous == "/"
  }
}
