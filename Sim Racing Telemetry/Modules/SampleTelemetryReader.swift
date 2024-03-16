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
//        laps.append(loadFromJSONFile(fileName: "sample-lap-1")!)
//        laps.append(loadFromJSONFile(fileName: "sample-lap-2")!)
//        laps.append(loadFromJSONFile(fileName: "sample-lap-3")!)
//        laps.append(loadFromJSONFile(fileName: "sample-lap-4")!)
//        laps.append(loadFromJSONFile(fileName: "sample-lap-5")!)
//        
//        laps.forEach { lap in
//            telemetry.append(contentsOf: lap.telemetry)
//        }
//        
//        laps[0].lapTime = laps[1].telemetry[0].lapTimeLastMs
//        laps[1].lapTime = laps[2].telemetry[0].lapTimeLastMs
//        laps[2].lapTime = laps[3].telemetry[0].lapTimeLastMs
//        laps[3].lapTime = laps[4].telemetry[0].lapTimeLastMs
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
