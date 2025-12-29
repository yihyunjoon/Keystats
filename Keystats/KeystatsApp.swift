import SwiftUI

@main
struct KeystatsApp: App {
    var body: some Scene {
        WindowGroup {
            KeystatsSplitView()
                .frame(minWidth: 600, minHeight: 380)
        }
        .defaultSize(width: 800, height: 480)
    }
}
