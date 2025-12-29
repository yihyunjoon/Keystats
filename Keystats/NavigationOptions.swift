import SwiftUI

/// An enumeration of navigation options in the app.
enum NavigationItem: Equatable, Hashable, Identifiable {
    /// A case that represents viewing the dashboard with key statistics overview.
    case dashboard
    /// A case that represents viewing detailed statistics.
    case statistics
    /// A case that represents viewing the app's settings.
    case settings

    static let mainPages: [NavigationItem] = [.dashboard, .statistics, .settings]

    var id: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .statistics: return "Statistics"
        case .settings: return "Settings"
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .dashboard: LocalizedStringResource("Dashboard", comment: "Title for the Dashboard tab, shown in the sidebar.")
        case .statistics: LocalizedStringResource("Statistics", comment: "Title for the Statistics tab, shown in the sidebar.")
        case .settings: LocalizedStringResource("Settings", comment: "Title for the Settings tab, shown in the sidebar.")
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "keyboard"
        case .statistics: "chart.bar"
        case .settings: "gear"
        }
    }

    /// A view builder that the split view uses to show a view for the selected navigation option.
    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .dashboard: DashboardView()
        case .statistics: StatisticsView()
        case .settings: SettingsView()
        }
    }
}
