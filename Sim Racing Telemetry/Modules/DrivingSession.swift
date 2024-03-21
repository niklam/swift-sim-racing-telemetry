//
//  DrivingSession.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation

class DrivingSession: NSObject, Identifiable, ObservableObject, Codable {
    var id: UUID = UUID()
    
    var sessionStarted: TimeInterval = Date().timeIntervalSince1970
    
    var game: SupportedGames = .GT7
    
    var name: String = "New session"
    
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
        case id, sessionStarted, game, name, totalLaps, currentlyOnLap, laps, lapCurrent, lapFastest, lapLast, telemetry
    }
    
    public enum SupportedGames: String, Codable {
        case GT7
    }
    
    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sessionStarted = try container.decode(TimeInterval.self, forKey: .sessionStarted)
        game = try container.decode(SupportedGames.self, forKey: .game)
        _totalLaps = Published(initialValue: try container.decode(Int.self, forKey: .totalLaps))
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        
        if name == "" {
            let date = Date(timeIntervalSinceReferenceDate: sessionStarted)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: date)
            name = formattedDate
        }
        
        let storedTelemetry: [TelemetryData] = try container.decode([TelemetryData].self, forKey: .telemetry)
        
        super.init()
        
        addTelemetry(storedTelemetry)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(sessionStarted, forKey: .sessionStarted)
        try container.encode(name, forKey: .name)
        try container.encode(totalLaps, forKey: .totalLaps)
        try container.encode(game, forKey: .game)
        try container.encode(telemetry, forKey: .telemetry)
    }
}

extension DrivingSession {
    public func addTelemetry(_ telemetryCollection: [TelemetryData], onLapCompletion: ((DrivingSession, Int) -> Void)? = nil) {
        var currentLap = self.telemetry.last?.currentLapNumber ?? 0
        
        telemetryCollection.forEach { telemetry in
            
//            var likelyRestarted = currentLap > 0 && telemetry.currentLapNumber == 0
            
            if telemetry.isPaused {
                return
            }

            if telemetry.currentLapNumber == 0 {
                self.totalLaps = telemetry.totalNumberOfLaps
                self.gridPosition = telemetry.gridPosition
                self.gridSize = telemetry.gridSize
                
                self.lapCurrent = Lap()
                self.telemetry = []
                
                return
            }
            
            if telemetry.isInRace == false {
                return
            }
            
            self.lapCurrent.telemetry.append(telemetry)
            self.telemetry.append(telemetry)
            
//            var raceIsOver = (self.totalLaps > 0 && telemetry.currentLapNumber > self.totalLaps)
            
            if currentLap != telemetry.currentLapNumber {
                if currentLap != 0 {
                    self.lapLast = self.lapCurrent
                    self.lapLast.lapTime = telemetry.lapTimeLastMs
                    
                    self.laps.append(lapLast)
                    
                    if self.lapFastest.lapTime <= 0
                        || self.lapFastest.lapTime > self.lapLast.lapTime {
                        self.lapFastest = self.lapLast
                    }
                    
                    self.lapCurrent = Lap()
                    self.lapCurrent.lapNumber = telemetry.currentLapNumber
                    self.lapCurrent.telemetry.append(telemetry)
                }
                
                self.currentlyOnLap = telemetry.currentLapNumber
                
                onLapCompletion?(self, currentLap)
                
                currentLap = telemetry.currentLapNumber
            }
        }
    }
}

extension DrivingSession {
    public func reset() {
        myDebugPrint("DrivingSession.reset")
        
        id = UUID()
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
    
    static var _sampleSession1: DrivingSession?
    
    static var sampleSession1: DrivingSession {
        
        if _sampleSession1 != nil {
            return _sampleSession1!
        }
        
        guard let session = DrivingSession.loadMultiFileSessionJson(sessionId: "1710682718") else {
            myDebugPrint("Failed to load sample session data, returning empty session")
            
            return DrivingSession()
        }
        
        _sampleSession1 = session
        
        return session
    }
    
    /// Doesn't belong to this class
    public static func saveToJSONFile(objects: DrivingSession, storeMultipart: Bool = true) {
        if objects.telemetry.count == 0 {
            print("Won't save empty sessions")
            
            return
        }
        
        let encoder = JSONEncoder()
        
        var sessionToStore: DrivingSession = objects
        
        var fileName = "session-\(Int(objects.sessionStarted))"
        
        if storeMultipart {
            sessionToStore = DrivingSession()
            sessionToStore.clone(drivingSession: objects)
            sessionToStore.telemetry = sessionToStore.lapLast.telemetry
            
            fileName.append("-\(objects.laps.count)")
        }
        
        do {
            let data = try encoder.encode(sessionToStore)
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
    public static func loadFromJSONFile(fileName: String) -> DrivingSession? {
        
        let decoder = JSONDecoder()
        do {
            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentDirectory.appendingPathComponent("\(fileName).json")
                let data = try Data(contentsOf: fileURL)
                let objects = try decoder.decode(DrivingSession.self, from: data)
                
                return objects
            }
        } catch {
            print("Error loading objects from JSON: \(error)")
        }
        
        return nil
    }
    
    public static func loadMultiFileSessionJson(sessionId: String) -> DrivingSession? {
        let drivingSession = DrivingSession()
        var fileNumber = 1
        
        while (true) {
            let fileName = "session-\(sessionId)-\(fileNumber)"
            
            guard let newData = DrivingSession.loadFromJSONFile(fileName: fileName) else {
                if fileNumber == 1 {
                    return nil
                }
                
                return drivingSession
            }
            
            myDebugPrint("Loaded data from partial file \(fileName)")
            
            if fileNumber == 1 {
                drivingSession.clone(drivingSession: newData)
            }
            
            if fileNumber > 1 {
                drivingSession.addTelemetry(newData.telemetry)
            }
            
            fileNumber += 1
        }
    }
}
