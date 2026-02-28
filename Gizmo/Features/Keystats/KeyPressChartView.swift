import Charts
import SwiftUI

struct KeyPressChartView: View {
  let records: [KeyPressRecord]

  private let maxDisplayedKeyCount = 20
  private let minVisibleBarCount = 12
  private let barWidth: CGFloat = 28

  private var displayedRecords: [KeyPressRecord] {
    Array(records.prefix(maxDisplayedKeyCount))
  }

  private var isTruncated: Bool {
    records.count > displayedRecords.count
  }

  private var chartWidth: CGFloat {
    let count = max(displayedRecords.count, minVisibleBarCount)
    return CGFloat(count) * barWidth
  }

  var body: some View {
    if records.isEmpty {
      ContentUnavailableView(
        String(localized: "No Data Yet"),
        systemImage: "keyboard",
        description: Text(String(localized: "Start typing to see your keyboard statistics."))
      )
      .frame(height: 300)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        if isTruncated {
          Text("Showing top \(displayedRecords.count) keys by press count.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        ScrollView(.horizontal, showsIndicators: true) {
          Chart(displayedRecords) { record in
            BarMark(
              x: .value(String(localized: "Key"), record.keyName),
              y: .value(String(localized: "Count"), record.count)
            )
            .annotation(position: .top, alignment: .center) {
              if displayedRecords.count <= 15 {
                Text("\(record.count)")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .chartXAxis {
            AxisMarks(values: .automatic) { value in
              AxisValueLabel {
                if let keyName = value.as(String.self) {
                  Text(shortKeyName(for: keyName))
                    .lineLimit(1)
                }
              }
            }
          }
          .chartYAxis {
            AxisMarks(position: .leading)
          }
          .chartYScale(
            domain: .automatic(dataType: Int.self) { domain in
              domain.append(100)
            }
          )
          .padding(.vertical, 8)
          .frame(width: chartWidth, height: 300)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding()
    }
  }

  private func shortKeyName(for keyName: String) -> String {
    switch keyName {
    case "Keypad Enter":
      return "KP ↩"
    case "Keypad Clear":
      return "KP Clr"
    case "Volume Up":
      return "Vol +"
    case "Volume Down":
      return "Vol -"
    default:
      if keyName.hasPrefix("Keypad ") {
        return "KP \(keyName.dropFirst("Keypad ".count))"
      }
      return keyName
    }
  }
}
