//
//  DrivingSession.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation

class DrivingSession: NSObject, Identifiable, ObservableObject, Codable {
    var sessionStarted: TimeInterval = Date().timeIntervalSince1970
    
    var game: SupportedGames = .GT7
    
    /// How many laps the race is
    @Published var totalLaps: Int = 0
    
    /// The lap currently on-going
    @Published var currentlyOnLap: Int = 0
    
    /// Data about completed laps
    @Published var laps: [Lap] = []
    
    /// Currently on-going lap's information
    @Published var lapCurrent: Lap = Lap()
    
    /// Fastets lap's information
    @Published var lapFastest: Lap = Lap()
    
    /// Last lap's information
    @Published var lapLast: Lap = Lap()
    
    @Published var gridPosition: Int = 0
    
    @Published var gridSize: Int = 1
    
    /// Telemetry information
    @Published var telemetry: [TelemetryData] = []
    
    private enum CodingKeys: String, CodingKey {
        case sessionStarted, game, /*totalLaps, currentlyOnLap, laps, lapCurrent, lapFastest, lapLast,*/ telemetry
    }
    
    public enum SupportedGames: String, Codable {
        case GT7
    }
    
    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sessionStarted = try container.decode(TimeInterval.self, forKey: .sessionStarted)
        game = try container.decode(SupportedGames.self, forKey: .game)
//        _totalLaps = Published(initialValue: try container.decode(Int.self, forKey: .totalLaps))
//        _currentlyOnLap = Published(initialValue: try container.decode(Int.self, forKey: .currentlyOnLap))
//        _laps = Published(initialValue: try container.decode([Lap].self, forKey: .laps))
//        _lapCurrent = Published(initialValue: try container.decode(Lap.self, forKey: .lapCurrent))
//        _lapFastest = Published(initialValue: try container.decode(Lap.self, forKey: .lapFastest))
//        _lapLast = Published(initialValue: try container.decode(Lap.self, forKey: .lapLast))
        _telemetry = Published(initialValue: try container.decode([TelemetryData].self, forKey: .telemetry))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sessionStarted, forKey: .sessionStarted)
        try container.encode(game, forKey: .game)
        try container.encode(telemetry, forKey: .telemetry)
    }
}

extension DrivingSession {
    public func processTelemetry(telemetryCollection: [TelemetryData]) {
        var currentLap = self.telemetry.last?.currentLapNumber ?? 0
        
        telemetryCollection.forEach { telemetry in
            if telemetry.packageId == 813596 {
                self.reset()
                currentLap = 0
            }
            
            if telemetry.currentLapNumber == 0 {
                self.totalLaps = telemetry.totalNumberOfLaps
                self.gridPosition = telemetry.preRacePosition
                self.gridSize = telemetry.numberOfCarsStartingRace
            }
            
            self.lapCurrent.telemetry.append(telemetry)
            self.telemetry.append(telemetry)
            
            if currentLap != telemetry.currentLapNumber && currentLap != 0 {
                currentLap = telemetry.currentLapNumber
                
                self.lapLast = self.lapCurrent
                self.lapLast.lapTime = telemetry.lapTimeLastMs
                
                if self.lapFastest.lapTime == 0
                    || self.lapFastest.lapTime > self.lapLast.lapTime {
                    self.lapFastest = self.lapLast
                }
                
                self.lapCurrent = Lap()
                self.lapCurrent.telemetry.append(telemetry)
                
                self.currentlyOnLap = currentLap
                
                //telemetryViewDrivingSession.clone(drivingSession: drivingSession)
            }
        }
    }
}

extension DrivingSession {
    public func reset() {
        myDebugPrint("DrivingSession.reset")
        
        sessionStarted = Date().timeIntervalSince1970
        totalLaps = 0
        currentlyOnLap = 0
        laps = []
        lapCurrent = Lap()
        lapLast = Lap()
        lapFastest = Lap()
        telemetry = []
    }
    
    public func clone(drivingSession: DrivingSession) {
        myDebugPrint("DrivingSession.clone")
        
        sessionStarted = drivingSession.sessionStarted
        totalLaps = drivingSession.totalLaps
        currentlyOnLap =  drivingSession.currentlyOnLap
        laps =  drivingSession.laps
        lapCurrent =  drivingSession.lapCurrent
        lapLast =  drivingSession.lapLast
        lapFastest =  drivingSession.lapFastest
        telemetry = drivingSession.telemetry
    }
    
    public func updateFrom(drivingSession: DrivingSession) {
        myDebugPrint("DrivingSession.updateFrom")
        
        sessionStarted = drivingSession.sessionStarted
        totalLaps = drivingSession.totalLaps
        currentlyOnLap =  drivingSession.currentlyOnLap
        laps =  drivingSession.laps
        lapCurrent =  drivingSession.lapCurrent
        lapLast =  drivingSession.lapLast
        lapFastest =  drivingSession.lapFastest
        telemetry = drivingSession.telemetry
    }
    
    static var sampleSession1: DrivingSession {
        let session = DrivingSession()
        
        session.totalLaps = 5
        session.currentlyOnLap = 2
        session.lapLast = Lap.sampleLap
        session.lapFastest = Lap.sampleLap
        
        session.lapCurrent = Lap.sampleLap
        session.lapCurrent.lapTime = 0
        session.lapCurrent.telemetry = Array(session.lapCurrent.telemetry.prefix(1500))
        
        session.telemetry = session.lapCurrent.telemetry
        
        return session
    }
    
    /// Doesn't belong to this class
    public static func saveToJSONFile(objects: DrivingSession) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(objects)
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("session-\(Int(objects.sessionStarted)).json")
                try data.write(to: fileURL)
                print("Saved to JSON file at: \(fileURL)")
            }
        } catch {
            print("Error saving objects to JSON: \(error)")
        }
    }

    /// Doesn't belong to this class
    public static func loadFromJSONFile(sessionStarted: Int) -> DrivingSession? {
        let decoder = JSONDecoder()
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("session-\(sessionStarted).json")
                let data = try Data(contentsOf: fileURL)
                let objects = try decoder.decode(DrivingSession.self, from: data)
                
                return objects
            }
        } catch {
            print("Error loading objects from JSON: \(error)")
        }
        return nil
    }
}
