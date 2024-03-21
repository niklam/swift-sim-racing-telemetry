//
//  SampleTelemetryReader.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 14.3.2024.
//

import Foundation

class SampleTelemetryReader: TelemetryReader {
    var laps: [Lap] = []
    var telemetry: [TelemetryData] = []
    var telemetryItemToReturn = -1
    var timerNotification: DispatchSourceTimer?
    var timerCollector: DispatchSourceTimer?
    var dataQueue: DispatchQueue?
    var dataQueueData: [TelemetryData] = []
    
    init() {
        guard let sessionData = DrivingSession.loadMultiFileSessionJson(sessionId: "1710682718") else {
            return
        }
        
        telemetry = sessionData.telemetry
    }
    
    func setHost(_ host: String) {
        // Do nothing
    }
    
    func fetch() {
        cancel()
        telemetryItemToReturn = 0
        
        let dataQueueLabel = String(format: "%s.dataQueue", Bundle.main.bundleIdentifier ?? "com.emptymonkey.dataqueue")
        self.dataQueue = DispatchQueue(label: dataQueueLabel)
        
        timerCollector = DispatchSource.makeTimerSource(queue: self.dataQueue)
        timerCollector?.schedule(deadline: .now(), repeating: DispatchTimeInterval.microseconds(4000)) // 8.333 ms should be close to "real time"
        timerCollector?.setEventHandler { [weak self] in
            self?.telemetryItemToReturn += 1
            
            if self?.telemetry.count == 0 {
                self?.cancel()
                
                return
            }
            
            if (self?.telemetryItemToReturn ?? 0) >= (self?.telemetry.count ?? 0) {
                self?.telemetryItemToReturn = 0
            }
            
            guard let item = self?.telemetry[self?.telemetryItemToReturn ?? -1] else {
                self?.cancel()
                
                return
            }
            
            self?.dataQueue?.async {
                self?.dataQueueData.append(item)
            }
        }
        timerCollector?.activate()
        
        
        timerNotification = DispatchSource.makeTimerSource()
        timerNotification?.schedule(deadline: .now(), repeating: DispatchTimeInterval.milliseconds(100))
        timerNotification?.setEventHandler { [weak self] in
            self?.dataQueue?.async {
                TelemetryReaderNotification.newTelemetry(telemetryDataArray: self?.dataQueueData ?? [])
                self?.dataQueueData.removeAll()
            }
        }
        timerNotification?.activate()
    }
    
    func cancel() {
        timerNotification?.cancel()
        timerNotification = nil
        
        timerCollector?.cancel()
        timerCollector = nil
    }
    
    /// Doesn't belong to this class
    func loadFromJSONFile(fileName: String) -> Lap? {
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
