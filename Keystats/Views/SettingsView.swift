import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text(String(localized: "Settings"))
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
