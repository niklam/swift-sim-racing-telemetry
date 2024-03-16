//
//  TelemetryReader.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 12.3.2024.
//

import Foundation

protocol TelemetryReader {
    func fetch()
    
    func cancel()
}

class TelemetryReaderNotification {
    static func newTelemetry(telemetryDataArray: [TelemetryData]) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .newTelemetry, object: nil, userInfo: ["telemetryDataArray": telemetryDataArray])
        }
    }
    
    static func gamePaused() {
        NotificationCenter.default.post(name: .gamePaused, object: nil)
    }
    
    static func gameUnPaused() {
        NotificationCenter.default.post(name: .gameUnPaused, object: nil)
    }
}

extension Notification.Name {
    static let newTelemetry = Notification.Name("newTelemetry")
    static let gamePaused = Notification.Name("gamePaused")
    static let gameUnPaused = Notification.Name("gameUnPaused")
}
