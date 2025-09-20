//
//  MessageEntry.swift
//  watchOS-mqtt-sample
//
//  Created by Sven Kobow on 20.09.25.
//
import Foundation

struct MessageEntry: Identifiable, Equatable {
    let id = UUID()
    let topic: String
    let payload: String
    let timestamp: Date
}
