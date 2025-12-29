import SwiftUI

struct KeystatsSplitView: View {
    @State private var selectedItem: NavigationItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.mainPages, selection: $selectedItem) { item in
                Label(
                    String(localized: item.name),
                    systemImage: item.symbolName
                )
                .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 250)
        } detail: {
            if let selectedItem {
                selectedItem.viewForPage()
            } else {
                Text(String(localized: "Select an item"))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    KeystatsSplitView()
}
