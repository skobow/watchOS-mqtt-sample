import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var client: MQTTWatchClient

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Circle()
                        .fill(client.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(client.connectionStatus)
                        .font(.footnote)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityIdentifier("statusLabel")
                }
            }

            List {
                ForEach(client.messages.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.topic)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.payload)
                            .font(.body)
                    }
                }
            }
            .listStyle(.carousel)

            Button(action: client.publishGreeting) {
                Text("Send Hello")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!client.isConnected)
        }
        .padding(.vertical, 8)
        .task {
            await client.connectIfNeeded()
        }
        .onReceive(client.reconnectPublisher) { _ in
            Task {
                await client.connectIfNeeded(force: true)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MQTTWatchClient.preview)
    }
}
