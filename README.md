# watchOS MQTT Sample

## NOTE: As watchOS does not support low-level network access (see [TN3135](https://developer.apple.com/documentation/technotes/tn3135-low-level-networking-on-watchos?utm_source=chatgpt.com)) this sample does not work on real hardware!


A minimal watchOS app that demonstrates how to connect to an MQTT broker from
SwiftUI using [MQTTNIO](https://github.com/swift-server/MQTTNIO). The app shows
the current connection state, streams incoming messages, and lets the user send
a simple greeting payload.

![Demo](assets/demo.gif)

## Features

- Connects to an MQTT broker over WebSockets with optional TLS support.
- Displays connection status in real time inside a compact watchOS layout.
- Lists the latest MQTT payloads received on `watch/<clientId>/receive`.
- Publishes a "Hello MQTT!" message to `watch/<clientId>/send` with QoS 1.
- Automatically retries the connection after transient failures.

## Requirements

- Xcode 15 or newer.
- watchOS 10 SDK.
- An MQTT broker reachable from the watch (or simulator). The default
  configuration targets `mqtt.backbone.arpa:8000` with an unauthenticated
  WebSocket endpoint at `/mqtt`.

## Getting started

1. Clone the repository and open `watchOS-mqtt-sample.xcodeproj` in Xcode.
2. Select the **watchOS-mqtt-sample Watch App** scheme and choose an Apple Watch
   simulator or a paired device.
3. Update the MQTT configuration if needed (see below).
4. Build and run the app. The status indicator will show `Connecting…` until the
   broker handshake completes. Once connected, the **Send Hello** button becomes
   active.

### Configuring the MQTT connection

The `MQTTWatchClient.Configuration` struct centralises the connection settings:

```swift
Configuration(
    host: "mqtt.backbone.arpa",
    port: 8000,
    path: "/mqtt",
    useTLS: false,
    username: nil,
    password: nil
)
```

To target a different broker:

- Adjust `host`, `port`, and `path` to match your WebSocket endpoint.
- Set `useTLS` to `true` when the server requires TLS. The default
  implementation currently disables certificate verification (`.none`); adapt
  the `TSTLSConfiguration` in `MQTTWatchClient.makeClient(force:)` for production
  use.
- Provide `username` and `password` if the broker mandates authentication.

The client subscribes to `watch/#`. Incoming messages are filtered in
`MQTTWatchClient` so that only payloads addressed to the watch's unique
identifier appear in the UI.

### Sending and receiving messages

- Tap **Send Hello** to publish a sample payload to
  `watch/<clientId>/send` with QoS 1.
- Any payload published by external systems to `watch/<clientId>/receive` will
  be appended to the list in reverse chronological order.

To experiment locally, you can run an MQTT broker (e.g., Mosquitto) that exposes
an unauthenticated WebSocket listener and publish messages to the expected
topics.

## Project structure

```
watchOS-mqtt-sample/
├── README.md
├── docs/
│   └── Architecture.md
└── watchOS-mqtt-sample/
    ├── watchOS-mqtt-sample Watch App/
    │   ├── ContentView.swift
    │   ├── MessageEntry.swift
    │   ├── MQTTWatchClient.swift
    │   └── watchOS_mqtt_sampleApp.swift
    ├── watchOS-mqtt-sample Watch AppTests/
    └── watchOS-mqtt-sample Watch AppUITests/
```

See [docs/Architecture.md](docs/Architecture.md) for a deeper dive into the
component responsibilities and data flow.

## Testing

The project currently includes placeholder unit and UI test targets. To run
tests, select **Product ▸ Test** in Xcode or execute:

```bash
xcodebuild test \
  -scheme "watchOS-mqtt-sample Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)"
```

Note: running tests requires an installed watchOS simulator that matches the
specified destination.

## Troubleshooting

- **Connection stuck on "Connecting…"** – Verify the broker URL and that the
  watch can reach the network. Check the Xcode debug console for MQTTNIO log
  output.
- **Authentication failures** – Ensure credentials are provided in the
  configuration and that the broker allows WebSocket clients.
- **Certificates rejected** – When enabling TLS, configure
  `TSTLSConfiguration` with the appropriate root certificates or switch to full
  verification mode.

## License

This project is distributed under the [MIT License](LICENSE.md). You are free
to use, modify, and share the code in accordance with the license terms.
