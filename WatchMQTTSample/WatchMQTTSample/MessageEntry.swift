import Foundation

struct MessageEntry: Identifiable, Equatable {
    let id = UUID()
    let topic: String
    let payload: String
    let timestamp: Date
}
