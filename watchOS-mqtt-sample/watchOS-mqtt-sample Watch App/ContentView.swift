//
//  ContentView.swift
//  watchOS-mqtt-sample Watch App
//
//  Created by Sven Kobow on 19.09.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var client: MQTTWatchClient
    
    var body: some View {
        VStack {
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
            .frame(maxHeight: .infinity)
            
            Button(action: client.publishGreeting) {
                Text("Send Hello")
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .disabled(!client.isConnected)
        }
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

#Preview {
    ContentView()
        .environmentObject(MQTTWatchClient.preview)
}
