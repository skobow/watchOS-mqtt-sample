# MQTT watchOS Sample

Dieses Repository enthält eine minimale watchOS Beispielapplikation, die zeigt, wie man mit [MQTTNio](https://github.com/adam-fowler/mqtt-nio) über WebSockets eine Verbindung zu einem MQTT Broker von einer eigenständigen Apple Watch Anwendung aufbaut. Die App visualisiert den Verbindungsstatus, listet eintreffende Nachrichten aus dem `watch/#` Topic und bietet einen Button, der "Hello MQTT!" auf `watch/hello` publiziert.

## Projektstruktur

```
WatchMQTTSample/
└── WatchMQTTSample/
    ├── ContentView.swift          // SwiftUI Oberfläche
    ├── MQTTWatchClient.swift      // MQTTNio Integration
    ├── MessageEntry.swift         // Modell für eingehende Nachrichten
    └── MQTTWatchSampleApp.swift   // App Entry Point
```

Die Dateien können einfach in ein neues **watchOS App** Projekt in Xcode kopiert werden. MQTTNio wird als Swift Package eingebunden.

## Vorbereitung in Xcode

1. Erstelle in Xcode ein neues Projekt vom Typ **watchOS App** (SwiftUI, minimal watchOS 9).
2. Aktiviere unter _General → Deployment_ die Option **App is independent**, damit die App auch ohne gekoppeltes iPhone über LTE funktionieren kann.
3. Füge unter _Signing & Capabilities_ die Berechtigung **Background Modes → Background fetch** hinzu, um MQTT Verbindungen stabil zu halten.
4. Öffne _File → Add Packages…_ und füge das Package `https://github.com/adam-fowler/mqtt-nio.git` mit der aktuellen Version hinzu.
5. Ersetze die automatisch generierten Dateien in der Watch App Zielgruppe mit den Dateien aus diesem Repository.

Die Standard-Konfiguration im Code verbindet sich verschlüsselt via WebSocket (`wss`) mit dem öffentlichen Testbroker `broker.emqx.io` auf Port `8084`. Passe `MQTTWatchClient.Configuration` nach Bedarf (Host, Pfad, Zugangsdaten) an.

## Laufzeitverhalten

* Beim Start stellt die App eine MQTT WebSocket-Verbindung her und abonniert `watch/#`.
* Eingehende Nachrichten erscheinen in einer Liste, neueste Einträge oben.
* Der Button **Send Hello** publiziert den Text "Hello MQTT!" auf `watch/hello`.
* Bei Verbindungsverlust versucht die App automatisch einen Reconnect.

## Hinweise

* Für produktive Einsätze sollten Zertifikate validiert, Fehlerzustände ausführlicher behandelt und ein persistentes Speichern der Nachrichten umgesetzt werden.
* Auf der Watch empfiehlt sich, den Broker mit kurzen Keep-Alive Intervallen und QoS 1 zu betreiben, um Mobilfunk-Nutzung zu optimieren.
