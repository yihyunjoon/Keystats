import Charts
import SwiftUI

struct KeyPressChartView: View {
    let records: [KeyPressRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .frame(height: 300)
        }
        .padding()
    }
}
