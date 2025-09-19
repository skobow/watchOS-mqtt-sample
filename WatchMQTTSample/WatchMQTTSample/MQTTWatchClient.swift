import Combine
import Foundation
import MQTTNIO
import NIO
import NIOSSL

@MainActor
final class MQTTWatchClient: ObservableObject {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }

    struct Configuration {
        var host: String
        var port: Int
        var path: String
        var useTLS: Bool
        var username: String?
        var password: String?

        static let `default` = Configuration(
            host: "broker.emqx.io",
            port: 8084,
            path: "/mqtt",
            useTLS: true,
            username: nil,
            password: nil
        )
    }

    @Published private(set) var connectionStatus: String = "Disconnected"
    @Published private(set) var messages: [MessageEntry] = []

    var isConnected: Bool { state == .connected }

    let reconnectPublisher = PassthroughSubject<Void, Never>()

    static let preview: MQTTWatchClient = {
        let client = MQTTWatchClient(configuration: .default, eventLoopGroupProvider: .singleton)
        client.connectionStatus = "Connected"
        client.messages = [
            MessageEntry(topic: "watch/preview", payload: "Hello MQTT!", timestamp: Date())
        ]
        client.state = .connected
        return client
    }()

    private let configuration: Configuration
    private let eventLoopGroupProvider: EventLoopProvider
    private var eventLoopGroup: EventLoopGroup?
    private var client: MQTTClient?
    private var state: ConnectionState = .disconnected {
        didSet {
            switch state {
            case .disconnected:
                connectionStatus = "Disconnected"
            case .connecting:
                connectionStatus = "Connecting…"
            case .connected:
                connectionStatus = "Connected"
            }
        }
    }

    init(configuration: Configuration = .default, eventLoopGroupProvider: EventLoopProvider = .createNew) {
        self.configuration = configuration
        self.eventLoopGroupProvider = eventLoopGroupProvider
    }

    deinit {
        if let eventLoopGroup {
            eventLoopGroup.shutdownGracefully { _ in }
        }
    }

    func connectIfNeeded(force: Bool = false) async {
        guard force || state == .disconnected else { return }
        state = .connecting

        do {
            let client = try await makeClient(force: force)
            try await connect(client: client)
            try await subscribe(client: client)
            state = .connected
        } catch {
            state = .disconnected
            connectionStatus = "Error: \(error.localizedDescription)"
            scheduleReconnect()
        }
    }

    func publishGreeting() {
        Task {
            do {
                guard let client else { throw MQTTWatchError.notConnected }
                var buffer = ByteBufferAllocator().buffer(capacity: 0)
                buffer.writeString("Hello MQTT!")
                try await withCheckedThrowingContinuation { continuation in
                    client.publish(to: "watch/hello", payload: buffer, qos: .atLeastOnce).whenComplete { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = "Publish failed: \(error.localizedDescription)"
                    self.state = .disconnected
                    self.scheduleReconnect()
                }
            }
        }
    }

    // MARK: - Private helpers

    private func makeClient(force: Bool) async throws -> MQTTClient {
        if force {
            try await tearDownClient()
        }

        if let client {
            return client
        }

        let eventLoopGroup = try await resolveEventLoopGroup()
        let configuration = try mqttConfiguration()
        let client = MQTTClient(configuration: configuration, eventLoopGroupProvider: .shared(eventLoopGroup))

        client.addMessageListener { [weak self] message, _ in
            guard let self else { return }
            let payload: String
            if var buffer = message.payload {
                payload = buffer.readString(length: buffer.readableBytes) ?? ""
            } else {
                payload = ""
            }

            Task { @MainActor in
                self.messages.append(MessageEntry(topic: message.topicName, payload: payload, timestamp: Date()))
                self.trimMessagesIfNeeded()
            }
        }

        self.client = client
        return client
    }

    private func connect(client: MQTTClient) async throws {
        try await withCheckedThrowingContinuation { continuation in
            client.connect().whenComplete { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func subscribe(client: MQTTClient) async throws {
        let subscriptions = [MQTTSubscribeInfo(topicFilter: "watch/#", qos: .atLeastOnce)]
        try await withCheckedThrowingContinuation { continuation in
            client.subscribe(to: subscriptions).whenComplete { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func mqttConfiguration() throws -> MQTTConfiguration {
        var tlsConfiguration: TLSConfiguration? = nil
        if configuration.useTLS {
            tlsConfiguration = .makeClientConfiguration()
        }

        return MQTTConfiguration(
            target: .host(configuration.host, port: configuration.port),
            protocolVersion: .version311,
            clientId: "watch-\(UUID().uuidString.prefix(8))",
            clean: true,
            keepAliveInterval: .seconds(30),
            connectTimeout: .seconds(5),
            tlsConfiguration: tlsConfiguration,
            transportConfig: .websocket(path: configuration.path, maxFrameSize: 1 << 14, additionalHTTPHeaders: [:]),
            username: configuration.username,
            password: configuration.password
        )
    }

    private func resolveEventLoopGroup() async throws -> EventLoopGroup {
        if let eventLoopGroup {
            return eventLoopGroup
        }

        let group: EventLoopGroup
        switch eventLoopGroupProvider {
        case .createNew:
            group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        case .shared(let existing):
            group = existing
        case .singleton:
            group = MultiThreadedEventLoopGroup.singleton
        }
        eventLoopGroup = group
        return group
    }

    private func tearDownClient() async throws {
        guard let client else { return }
        self.client = nil
        try await withCheckedThrowingContinuation { continuation in
            client.disconnect().whenComplete { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func trimMessagesIfNeeded(maxCount: Int = 20) {
        if messages.count > maxCount {
            messages.removeFirst(messages.count - maxCount)
        }
    }

    private func scheduleReconnect(delay seconds: Double = 5) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run {
                self?.reconnectPublisher.send(())
            }
        }
    }
}

extension MultiThreadedEventLoopGroup {
    static var singleton: MultiThreadedEventLoopGroup = {
        MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }()
}

extension MQTTWatchClient {
    enum EventLoopProvider {
        case createNew
        case shared(EventLoopGroup)
        case singleton
    }

    enum MQTTWatchError: Error {
        case notConnected
    }
}
