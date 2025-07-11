import SwiftUI

@main
struct ADS_BApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAppLifecycleManagement()
        }
    }
}
