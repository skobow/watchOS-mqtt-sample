# Architecture Overview

This document describes how the watchOS MQTT Sample app is structured and how the
MQTT client is integrated into the SwiftUI user interface.

## High-level structure

The project is a standalone watchOS app built with SwiftUI. It is organised into
three primary layers:

1. **Presentation layer** – SwiftUI views that render the UI and react to
   changes published by observable objects.
2. **Domain layer** – Lightweight models that capture the data shown in the UI.
3. **Infrastructure layer** – The MQTT client implementation that bridges the
   app with an MQTT broker using [MQTTNIO](https://github.com/swift-server/MQTTNIO).

All components are scoped to the watch target (`watchOS-mqtt-sample Watch App`).

## Key components

### `watchOS_mqtt_sample_Watch_AppApp`

The `@main` entry point configures global logging, sets up the shared
`MQTTWatchClient`, and injects it into the SwiftUI environment so that every
view can access the same connection state. `AppDelegate` also keeps a reference
to background refresh tasks, allowing the app to mark them as completed.

### `ContentView`

`ContentView` is the root SwiftUI view. It subscribes to the `MQTTWatchClient`
object through `@EnvironmentObject` and renders three sections:

- **Status header** showing the current connection state.
- **Message list** that displays MQTT payloads in reverse chronological order.
- **Send button** that publishes a "Hello MQTT!" message and is enabled only
  when the client is connected.

The view triggers the MQTT connection using a `.task` modifier and listens to a
custom `reconnectPublisher` to re-establish the connection when the client
signals a retry.

### `MQTTWatchClient`

`MQTTWatchClient` is an `ObservableObject` annotated with `@MainActor`. It wraps
an `MQTTClient` from MQTTNIO and exposes a high-level API tailored to the watch
app:

- Maintains the connection state and exposes a human-readable status string.
- Stores the most recent messages as `MessageEntry` values and trims the list to
  keep the UI responsive.
- Provides `connectIfNeeded(force:)`, `publishGreeting()`, and a
  `reconnectPublisher` for retry scheduling.

Internally, it configures a WebSocket MQTT connection (optionally secured with
TLS) and registers a publish listener restricted to topics under
`watch/<clientId>/receive`.

### `MessageEntry`

`MessageEntry` is a simple `Identifiable` struct. Each message stores its topic,
payload, and timestamp. The UI reverses the `messages` array to show the most
recent payloads first.

## Connection lifecycle

1. The view loads and asks the client to `connectIfNeeded()`.
2. The client attempts to instantiate an MQTT connection using
   `MQTTClient.WebSocketConfiguration` and a singleton `NIOTSEventLoopGroup`.
3. On success, it subscribes to `watch/#` topics so that the watch can receive
   messages addressed to its unique client identifier.
4. If an error occurs, the client updates the status string, schedules a
   reconnect attempt after a short delay, and emits a signal through
   `reconnectPublisher`.
5. When the user taps **Send Hello**, the client publishes a message to
   `watch/<clientId>/send` with QoS 1. Failures trigger a state reset and a
   reconnect schedule.

## Extensibility notes

- **Custom topics** – Extend the publish helper or add new methods that write to
  other topics. Update the listener closure to handle additional payloads.
- **Authentication** – Supply a username and password via
  `MQTTWatchClient.Configuration`. TLS verification can also be tightened by
  providing certificates in the `TSTLSConfiguration` setup.
- **Offline storage** – Swap the in-memory `messages` array for a persistence
  layer (e.g., Core Data or file storage) if message history needs to survive
  app restarts.

## Data flow diagram

```
+-------------+     connectIfNeeded()     +-------------------+
| ContentView | ------------------------> | MQTTWatchClient   |
|             | <---- status/messages --- |  (ObservableObject)|
+-------------+                           +---------+---------+
       |                                              |
       | publishGreeting()                            | MQTTNIO publish/subscribe
       v                                              v
+------------------+                     +-----------------------------+
| MQTT Broker      | <--- WebSocket ---> | MQTTNIO / SwiftNIO pipeline |
+------------------+                     +-----------------------------+
```

The SwiftUI view reacts to published changes, while the MQTT client encapsulates
all networking details.
