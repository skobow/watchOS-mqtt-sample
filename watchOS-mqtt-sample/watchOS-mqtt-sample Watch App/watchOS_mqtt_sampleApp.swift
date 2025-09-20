//
//  watchOS_mqtt_sampleApp.swift
//  watchOS-mqtt-sample Watch App
//
//  Created by Sven Kobow on 19.09.25.
//
import WatchKit
import SwiftUI
import Logging

final class AppDelegate: NSObject, WKApplicationDelegate {
    private var backgroundTask: WKRefreshBackgroundTask?
    
    func applicationDidBecomeActive() {
        
    }
    
    func applicationDidFinishLaunching() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug   // oder .trace für ganz viel Output
            return handler
        }
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            backgroundTask = task
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

@main
struct watchOS_mqtt_sample_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var mqttClient = MQTTWatchClient()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mqttClient)
        }
    }
}
