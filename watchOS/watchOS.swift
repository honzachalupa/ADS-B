import SwiftUI

@main
struct ADS_B_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .withAppLifecycleManagement()
        }
    }
}
