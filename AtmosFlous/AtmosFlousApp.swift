import SwiftUI

@main
struct AtmosFlousApp: App {

    // Required so OneSignal gets the real launch options.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            CloudSurfSoft()
        }
    }
}
