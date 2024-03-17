//
//  TelemetryCollection.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation
import SwiftData


class Lap: Codable, Identifiable {
    public var id: UUID = UUID()
    public var telemetry: [TelemetryData] = []
    public var lapTime: Int = 0
    public var lapNumber: Int = 0
    public var timeStamp: TimeInterval = Date().timeIntervalSince1970
    
    enum CodingKeys: String, CodingKey {
        case id, telemetry, lapTime, lapNumber, timeStamp
    }
    
    init() {
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Attempt to decode the `id` if it exists, otherwise keep the default UUID
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        telemetry = try container.decode([TelemetryData].self, forKey: .telemetry)
        lapTime = try container.decode(Int.self, forKey: .lapTime)
        lapNumber = try container.decode(Int.self, forKey: .lapNumber)
        timeStamp = try container.decode(TimeInterval.self, forKey: .timeStamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all properties, including the `id`
        try container.encode(id, forKey: .id)
        try container.encode(telemetry, forKey: .telemetry)
        try container.encode(lapTime, forKey: .lapTime)
        try container.encode(lapNumber, forKey: .lapNumber)
        try container.encode(timeStamp, forKey: .timeStamp)
    }
}


extension Lap {
    static var lapData: Lap?
    static var sampleLap: Lap {
        
        if let lap = lapData {
            return lap
        }
        
        lapData = Lap.loadFromJSONFile(fileName: "sample-lap-")!
        
        lapData?.lapNumber = lapData?.telemetry.first?.currentLapNumber ?? 0
        
        myDebugPrint("Lap contains \(lapData!.telemetry.count) telemetry points")
        myDebugPrint("1 telemetry point every \(Float(lapData!.lapTime) / Float(lapData!.telemetry.count)) ms")
        myDebugPrint(String(format: "Lap time: %d:%.3f", lapData!.lapTime / 60, lapData!.lapTime % 60))
        
        return lapData!
    }
    
    /// Doesn't belong to this class
    public static func saveToJSONFile(objects: Lap, fileName: String) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(objects)
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("\(fileName).json")
                try data.write(to: fileURL)
                print("Saved to JSON file at: \(fileURL)")
            }
        } catch {
            print("Error saving objects to JSON: \(error)")
        }
    }

    /// Doesn't belong to this class
    public static func loadFromJSONFile(fileName: String) -> Lap? {
        let decoder = JSONDecoder()
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("\(fileName).json")
                let data = try Data(contentsOf: fileURL)
                let objects = try decoder.decode(Lap.self, from: data)
                return objects
            }
        } catch {
            print("Error loading objects from JSON: \(error)")
        }
        return nil
    }
}
