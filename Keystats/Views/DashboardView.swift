import SwiftUI

struct DashboardView: View {
    var body: some View {
        VStack {
            Text(String(localized: "Dashboard"))
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DashboardView()
}
