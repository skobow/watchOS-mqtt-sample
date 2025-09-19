import SwiftUI
import WatchKit

final class AppDelegate: NSObject, WKApplicationDelegate {
    private var backgroundTask: WKRefreshBackgroundTask?

    func applicationDidBecomeActive() {
        WKExtension.shared().isFrontmostTimeoutExtended = true
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            backgroundTask = task
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

@main
struct MQTTWatchSampleApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var mqttClient = MQTTWatchClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mqttClient)
        }
    }
}
