//
//  TelemetryCollection.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation

class Lap: ObservableObject, Codable {
    /// Telemetry data
    public var telemetry: [Gt7Data] = []
    
    /// Lap time in milliseconds
    public var lapTime: Int = 0
}

extension Lap {
    static var sampleLap: Lap {
        // This is a retarded way of doing this and must be fixed
        let reader = UdpReader(host: "localhost")
        let lap = reader.loadFromJSONFile(fileName: "telemetry-sample")!
        
        print("Lap contains \(lap.telemetry.count) telemetry points")
        print("1 telemetry point every \(Float(lap.lapTime) / Float(lap.telemetry.count)) ms")
        print(String(format: "Lap time: %d:%.3f", lap.lapTime / 60, lap.lapTime % 60))
        
        return lap
    }
}
