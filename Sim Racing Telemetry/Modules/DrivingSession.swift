//
//  DrivingSession.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation

class DrivingSession: NSObject, Identifiable, ObservableObject {
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
    
    /// Id of the car
    @Published var carId: Int = 0
    
    /// Telemetry information
    @Published var telemetry: [Gt7Data] = []
}

extension DrivingSession {
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
}
