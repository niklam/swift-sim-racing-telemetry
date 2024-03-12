//
//  HeartbeatManager.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation
import Network

class HeartbeatManager {
    private var timer: Timer?
    private let heartbeatInterval = TimeInterval(5)
    
    var host: String
    var port: UInt16
    
    init(host: String, port: UInt16 = 33739) {
        print("Initializing HeartbeatManager with host \(host):\(port)")
        self.host = host
        self.port = port
    }
    
    /// Start sending heartbeats
    public func startHeartbeat() {
        stopHeartbeat()
        print("Start heartbeat")
        sendHeartbeat()
        
        timer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    /// Stop sending heartbeats
    public func stopHeartbeat() {
        print("Stop heartbeat")
        timer?.invalidate()
        timer = nil
    }
    
    private func sendHeartbeat() {
        let host = NWEndpoint.Host(stringLiteral: host)
        let port = NWEndpoint.Port(integerLiteral: self.port)
        
        let connection = NWConnection(host: host, port: port, using: .udp)
        
        connection.start(queue: .global(qos: .background))
        
        let sendContent = "A"
        if let sendData = sendContent.data(using: .utf8) {
            connection.send(content: sendData, completion: .contentProcessed({ error in
                if let error = error {
                    print("Error occurred with heartbeat: \(error)")
                } else {
                    print("Hearbeat sent.")
                }
                
                // Optionally, you might want to close the connection after sending
                connection.cancel()
            }))
        } else {
            print("Failed to encode string to data.")
        }
    }
}
