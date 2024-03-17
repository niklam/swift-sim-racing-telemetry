//
//  Gt7TelemetryReader.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 12.3.2024.
//

import Foundation
import Network

class Gt7TelemetryReader: TelemetryReader {
    
    var host: NWEndpoint.Host
    var udpPort: NWEndpoint.Port
    
    /// UDP listener
    var listener: NWListener?
    
    var telemetryInterval: Int = 0
    var dataQueue: DispatchQueue?
    var timer: DispatchSourceTimer?
    var dataQueueData: [TelemetryData] = []
    
    var previouslyIsPaused: Bool? = nil
    var previouslyInRace: Bool? = nil
    
    var hearbeat: Gt7HeartbeatManager?
    
    init(host: NWEndpoint.Host = "localhost", udpPort: NWEndpoint.Port = 33740, telemetryInterval: Int = 0) {
        self.host = host
        self.udpPort = udpPort
        self.telemetryInterval = telemetryInterval
        
        self.hearbeat = Gt7HeartbeatManager(host: self.host)
    }
    
    func setHost(_ host: String) {
        self.host = NWEndpoint.Host(host)
    }
    
    func fetch() {
        self.hearbeat?.startHeartbeat()
        self.startTimer()
        
        print("Starting to listen for GT7 data on UDP \(self.udpPort)")
        
        DispatchQueue.global(qos: .background).async {
            self.listener = try! NWListener(using: .udp, on: self.udpPort)
            guard let listener = self.listener else {
                print("Couldn't start listener")
                return
            }
            
            listener.stateUpdateHandler = { state in
                switch state {
                case .setup:
                    print("Listener setup")
                case .waiting(let error):
                    print("Listener waiting with error: \(error)")
                case .ready:
                    print("Listener ready")
                case .failed(let error):
                    print("Listener failed with error: \(error)")
                case .cancelled:
                    print("Listener cancelled")
                @unknown default:
                    fatalError("Unknown listener state")
                }
            }
            
            listener.newConnectionHandler = { newConnection in
                newConnection.start(queue: .main)
                self.receive(on: newConnection)
            }
            
            // Start the listener on the main queue
            listener.start(queue: .global(qos: .background))
        }
    }
    
    public func cancel() {
        print("Closing GT7 data listener")
        
        self.hearbeat?.stopHeartbeat()
        
        self.listener?.cancel()
        
        self.timer?.cancel()
        self.timer = nil
    }
    
    func startTimer() {
        if telemetryInterval > 0 {
            let dataQueueLabel = String(format: "%s.dataQueue", Bundle.main.bundleIdentifier ?? "com.emptymonkey.dataqueue")
            self.dataQueue = DispatchQueue(label: dataQueueLabel)
            
            self.timer = DispatchSource.makeTimerSource(queue: self.dataQueue)
            self.timer?.schedule(deadline: .now(), repeating: DispatchTimeInterval.milliseconds(telemetryInterval))
            self.timer?.setEventHandler { [weak self] in
                guard let dataArray = self?.dataQueueData else {
                    return
                }
                
                self?.triggerNewTelemetry(telemetryArray: dataArray)
            }
            timer?.activate()
        }
    }
    
    func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            let decryptedData = self?.decryptData(data: data ?? Data())
            
            guard let gt7Data = Gt7Data(data: decryptedData ?? Data()) else {
                print("Invalid data...")
                
                self?.receive(on: connection)
                
                return
            }
            
            gt7Data.packageTime = Date().timeIntervalSince1970
            
            // If telemetry is such that it shouldn't be sent forward, processor return nil
            guard let telemetry = self?.processTelemetryData(gt7Data: gt7Data) else {
                self?.receive(on: connection)
                
                return
            }
            
            // If the telemetry notifications are expected immediately, send them immediately
            if self?.telemetryInterval == 0 {
                self?.triggerNewTelemetry(telemetry: telemetry)
            }
            
            // If the telemetry notifications are expected with an interval
            // just add the data to the queue and we're good.
            if self?.telemetryInterval ?? 0 > 0 {
                self?.dataQueue?.async {
                    self?.dataQueueData.append(telemetry)
                }
            }
            
            self?.receive(on: connection)
        }
    }
    
    func triggerNewTelemetry(telemetry: TelemetryData) {
        TelemetryReaderNotification.newTelemetry(telemetryDataArray: [telemetry])
    }
    
    func triggerNewTelemetry(telemetryArray: [TelemetryData]) {
        self.dataQueue?.async {
            TelemetryReaderNotification.newTelemetry(telemetryDataArray: telemetryArray)
            self.dataQueueData.removeAll()
        }
    }
    
    /// Process the incoming Gt7TelemetryData to TelemetryData
    /// Returns nil if package should not be added to the telemetry stack
    func processTelemetryData(gt7Data: Gt7Data) -> TelemetryData? {
        let telemetry = TelemetryData.from(gt7Data: gt7Data)
        
        if telemetry.isPaused {
            if self.previouslyIsPaused == false {
                self.previouslyIsPaused = true
                TelemetryReaderNotification.gamePaused()
                
                return nil
            }
        }
        
        if self.previouslyIsPaused == true && telemetry.isPaused {
            TelemetryReaderNotification.gameUnPaused()
            self.previouslyIsPaused = false
        }
        
        return telemetry
    }
    
    /// Decrypt GT7 telemetry package data
    /// Returns nil if provided data is not valid GT7 data
    func decryptData(data: Data) -> Data? {
        let key = [UInt8]("Simulator Interface Packet GT7 ver 0.0".utf8)
        let oiv = data.subdata(in: 0x40..<0x44)
        
        let iv1 = oiv.withUnsafeBytes { $0.load(as: UInt32.self) }
        let iv2 = iv1 ^ 0xDEADBEAF
        var nonce = Data()
        nonce.append(contentsOf: withUnsafeBytes(of: iv2.littleEndian, Array.init))
        nonce.append(contentsOf: withUnsafeBytes(of: iv1.littleEndian, Array.init))
        
        guard let decryptedData = Salsa20.xor(data: data, nonce: nonce, secretKey: Data(bytes: key, count: 32)) else {
            return nil
        }
        
        let magic = decryptedData[0..<4].withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // If magic is not 0x47375330, the data is invalid
        if magic != 0x47375330 {
            return nil
        }
        
        return decryptedData
    }
}


class Gt7HeartbeatManager {
    private var timer: Timer?
    private let heartbeatInterval = TimeInterval(5)
    
    var host: NWEndpoint.Host
    var port: UInt16
    
    init(host: NWEndpoint.Host, port: UInt16 = 33739) {
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
        let host = host
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
