import SwiftUI

struct StatisticsView: View {
    var body: some View {
        VStack {
            Text(String(localized: "Statistics"))
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StatisticsView()
}
