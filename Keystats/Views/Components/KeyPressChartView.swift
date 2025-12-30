import Charts
import SwiftUI

struct KeyPressChartView: View {
  let records: [KeyPressRecord]

  private let visibleKeyCount = 20
  private let barWidth: CGFloat = 30

  private var chartWidth: CGFloat {
    let count = max(records.count, visibleKeyCount)
    return CGFloat(count) * barWidth
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ScrollView(.horizontal, showsIndicators: true) {
        Chart(records) { record in
          BarMark(
            x: .value(String(localized: "Key"), record.keyName),
            y: .value(String(localized: "Count"), record.count)
          )
          .annotation(position: .top, alignment: .center) {
            if records.count <= 15 {
              Text("\(record.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisValueLabel()
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
        .frame(width: records.count > visibleKeyCount ? chartWidth : nil, height: 300)
      }
    }
    .padding()
  }
}
