# MQTT watchOS Sample

This repository contains a minimal watchOS sample application that demonstrates how to establish a WebSocket connection from an independent Apple Watch app to an MQTT broker using [MQTTNio](https://github.com/adam-fowler/mqtt-nio). The app visualizes the connection status, lists incoming messages from the `watch/#` topic, and exposes a button that publishes “Hello MQTT!” to `watch/hello`.

## Project structure

```
WatchMQTTSample/
└── WatchMQTTSample/
    ├── ContentView.swift          // SwiftUI interface
    ├── MQTTWatchClient.swift      // MQTTNio integration
    ├── MessageEntry.swift         // Model for incoming messages
    └── MQTTWatchSampleApp.swift   // App entry point
```

You can copy the files into a new **watchOS App** project in Xcode. MQTTNio is integrated as a Swift Package.

## Xcode setup

1. Create a new **watchOS App** project in Xcode (SwiftUI, minimum watchOS 9).
2. Enable **App is independent** under _General → Deployment_ so the app can operate over LTE without a paired iPhone.
3. Add **Background Modes → Background fetch** under _Signing & Capabilities_ to keep MQTT connections stable.
4. Open _File → Add Packages…_ and add the package `https://github.com/adam-fowler/mqtt-nio.git` at the current version.
5. Replace the auto-generated files in the watch app target with the files from this repository.

The default configuration in the code connects securely via WebSocket (`wss`) to the public test broker `broker.emqx.io` on port `8084`. Adjust `MQTTWatchClient.Configuration` as needed (host, path, credentials).

## Runtime behavior

* On launch, the app creates an MQTT WebSocket connection and subscribes to `watch/#`.
* Incoming messages appear in a list, with the latest entries at the top.
* The **Send Hello** button publishes the text “Hello MQTT!” to `watch/hello`.
* If the connection drops, the app automatically attempts to reconnect.

## Notes

* For production usage you should validate certificates, handle error states more comprehensively, and persist messages locally.
* On the watch it is advisable to configure the broker with short keep-alive intervals and QoS 1 to optimize cellular usage.
