import SwiftUI

enum NavigationItem: Equatable, Hashable, Identifiable {
    case dashboard

    static let mainPages: [NavigationItem] = [.dashboard]

    var id: String {
        switch self {
        case .dashboard: return "Dashboard"
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .dashboard:
            LocalizedStringResource(
                "Dashboard",
                comment: "Title for the Dashboard tab, shown in the sidebar."
            )
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "keyboard"
        }
    }

    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .dashboard: DashboardView()
        }
    }
}
