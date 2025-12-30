import SwiftUI

struct KeyboardHeatmapView: View {
    let records: [KeyPressRecord]

    private var maxCount: Int {
        records.map(\.count).max() ?? 1
    }

    private func count(for keyCode: Int) -> Int {
        records.first { $0.keyCode == keyCode }?.count ?? 0
    }

    private func intensity(for keyCode: Int) -> Double {
        guard maxCount > 0 else { return 0 }
        return Double(count(for: keyCode)) / Double(maxCount)
    }

    var body: some View {
        if records.isEmpty {
            ContentUnavailableView(
                String(localized: "No Data Yet"),
                systemImage: "keyboard",
                description: Text(String(localized: "Start typing to see your keyboard heatmap."))
            )
        } else {
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
            .padding()
        }
    }
}

struct KeyView: View {
    let keyCode: Int
    let width: CGFloat
    let count: Int
    let intensity: Double

    private var keyWidth: CGFloat {
        KeyboardLayoutData.baseKeySize * width +
            KeyboardLayoutData.keySpacing * (width - 1)
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
