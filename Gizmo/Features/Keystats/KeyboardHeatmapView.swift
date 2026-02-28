import SwiftUI

struct KeyboardHeatmapView: View {
  let records: [KeyPressRecord]
  private let targetPanelWidth: CGFloat = 560

  private var maxCount: Int {
    records.map(\.count).max() ?? 1
  }

  private var keyboardWidth: CGFloat {
    KeyboardLayoutData.rows.map { row in
      let keyWidths = row.reduce(CGFloat.zero) { partialResult, key in
        partialResult + KeyboardLayoutData.baseKeySize * key.width
      }
      let spacings = CGFloat(max(row.count - 1, 0)) * KeyboardLayoutData.keySpacing
      return keyWidths + spacings
    }
    .max() ?? 0
  }

  private var keyboardHeight: CGFloat {
    let rowCount = KeyboardLayoutData.rows.count
    let rowHeights = CGFloat(rowCount) * KeyboardLayoutData.baseKeySize
    let spacings = CGFloat(max(rowCount - 1, 0)) * KeyboardLayoutData.keySpacing
    return rowHeights + spacings
  }

  private var keyboardScale: CGFloat {
    guard keyboardWidth > 0 else { return 1 }
    return min(1, targetPanelWidth / keyboardWidth)
  }

  private func count(for keyCode: Int) -> Int {
    records.first { $0.keyCode == keyCode }?.count ?? 0
  }

  private func intensity(for keyCode: Int) -> Double {
    guard maxCount > 0 else { return 0 }
    return Double(count(for: keyCode)) / Double(maxCount)
  }

  private var keyboardGrid: some View {
    VStack(alignment: .center, spacing: KeyboardLayoutData.keySpacing) {
      ForEach(Array(KeyboardLayoutData.rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: KeyboardLayoutData.keySpacing) {
          ForEach(Array(row.enumerated()), id: \.offset) { _, key in
            KeyView(
              keyCode: key.keyCode,
              width: key.width,
              count: count(for: key.keyCode),
              intensity: intensity(for: key.keyCode)
            )
          }
        }
      }
    }
  }

  var body: some View {
    if records.isEmpty {
      ContentUnavailableView(
        String(localized: "No Data Yet"),
        systemImage: "keyboard",
        description: Text(String(localized: "Start typing to see your keyboard heatmap."))
      )
    } else {
      keyboardGrid
        .scaleEffect(keyboardScale, anchor: .topLeading)
        .frame(
          width: keyboardWidth * keyboardScale,
          height: keyboardHeight * keyboardScale,
          alignment: .topLeading
        )
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct KeyView: View {
  let keyCode: Int
  let width: CGFloat
  let count: Int
  let intensity: Double

  private var keyWidth: CGFloat {
    KeyboardLayoutData.baseKeySize * width + KeyboardLayoutData.keySpacing * (width - 1)
  }

  private var backgroundColor: Color {
    Color.accentColor.opacity(0.1 + intensity * 0.8)
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(KeyCodeMapping.name(for: keyCode))
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.5)

      if count > 0 {
        Text("\(count)")
          .font(.system(size: 9, design: .rounded))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: keyWidth, height: KeyboardLayoutData.baseKeySize)
    .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6))
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .strokeBorder(.quaternary, lineWidth: 1)
    )
  }
}

#Preview {
  KeyboardHeatmapView(records: [])
    .frame(width: 800, height: 400)
}
