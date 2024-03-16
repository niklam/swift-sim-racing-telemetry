//
//  UdpReader.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import Foundation
import Network
import Clibsodium

public class UdpReader {
    var connection: NWConnection?
    var listener: NWListener?
    var host: NWEndpoint.Host
    var udpPort: NWEndpoint.Port
    
    private var shouldSendHeatbeats = false
    
    var telemetryArray: [Gt7Data] = []
    var prevPackageSentTime: Int = 0
    var currentLapNumber: Int = 0
    
    /// A container for all laps driven
    var lapAllLaps: [Gt7Data] = []
    
    /// The previously driven lap
    var lapPrevious: [Gt7Data] = []
    
    /// The fastest lap
    var lapFastest: [Gt7Data] = []
    
    /// Currently on-going lap
    var lapCurrent: [Gt7Data] = []
    
    /// GT7 sends us 60 packages per second
    var tickTime: Float = 1000 / 60
    
    init(host: NWEndpoint.Host = "localhost", udpPort: NWEndpoint.Port = 33740) {
        self.host = host
        self.udpPort = udpPort
    }
    
    public func listen() {
        print("Starting to listen to \(self.host):\(self.udpPort)")
        
        /**/
//        var hexString = "5d8c f3d8 0a4b 583c b06c 7bac 551a f5c3 7e0c 487d 6666 dbb4 3e40 bbce 827d 0db1 eecb 0104 5244 ad48 221d e780 8465 7a14 7a1d c708 3cba e96e 8eb0 4638 f768 6481 449b 90ea fa8d a88f 8750 6f68 999d 90ed b302 50a2 3dfc f431 4ff5 0cef 6d57 7f97 07f7 8508 796a 1dfe 9d1b 0732 1a41 1428 f787 33f5 d0b9 c066 73ba d845 0746 738f 88fe 75f5 1fd8 f826 bfa2 5e95 e3fa e8ed a11d 158f e89d c269 ef89 f7c9 fa3b 280d d250 05ec e69f 16cd afbb 2d4b eb79 ed83 a94e 4d28 a68b 9f40 3937 ab35 3ac4 53f5 16d9 2549 f900 8465 779c 0ad5 f29d 9ac5 c128 3ff7 62df 5f07 0975 606e a40f 201c 0316 94ba 0c30 63c3 db15 42b8 9431 ccbf f217 4867 4d54 7222 7e99 e99c 585b c3f2 8b24 fc12 9788 0daa 4c26 efc0 ca10 611a 7afe 97e0 4e89 1721 8ad6 7dfd bbe9 fa9c 719b 7e23 374c 048b"
//        
//        let sodium = Sodium()
//        let dataBytes = sodium.utils.hex2bin(hexString, ignore: " ")!
//        
//        let ddata = decryptData(data: Data(bytes: dataBytes, count: dataBytes.count))
//        
//        let gt7data = Gt7Data(data: ddata!)
//        
//        DispatchQueue.global(qos: .background).async {
//            self.triggerNewDataEvent(gt7data: gt7data!)
//        }
//        
//        return
        /**/
        
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
            listener.start(queue: .main)
        }
    }
    
    public func cancel() {
        print("Closing listener")
        self.listener?.cancel()
        self.listener = nil
    }
    
    /// Triggers the telemetryDataUpdated notification
    /// Note, that it's only triggered once every 100 ms, no matter how often it's called. If the notification
    /// is not triggered, the telemetry data is collected, and then sent together with other telemetry once
    /// the notification actually triggers.
    ///
    /// This method contains a lot of logic that shouldn't be in it.
    func triggerNewDataEvent(gt7data: Gt7Data) {
        gt7data.packageTime = Date().timeIntervalSince1970
        
        let currentTimeMillis = Int(Date().timeIntervalSince1970 * 1000)
        
        if gt7data.isInRace == true && gt7data.isPaused == false {
            self.telemetryArray.append(gt7data)
        }
        
        var mustTrigger = false;
        
        if gt7data.currentLap != self.currentLapNumber {
            mustTrigger = true
            self.lapPrevious = self.lapCurrent
            self.lapCurrent = [gt7data]
            
            self.currentLapNumber = gt7data.currentLap
            
//            if self.currentLapNumber > 1 {
//                let lap = Lap()
//                lap.telemetry.append(TelemetryData.from(gt7Data: self.lapPrevious))
//                lap.lapTime = gt7data.lapTimeLastMs
////                saveToJSONFile(objects: lap, fileName: "sample-lap-\(gt7data.currentLap-1)")
//            }
        }
        
        if gt7data.currentLap == self.currentLapNumber {
            self.lapCurrent.append(gt7data)
        }
        
        // Only send the telemetry data 10 times per second. I did it this way
        // so that prevPackageSentTime can start as 0.
        if mustTrigger == false && self.prevPackageSentTime - currentTimeMillis < -100 {
            mustTrigger = true
        }
        
        if mustTrigger == false {
            return
        }
        
        self.prevPackageSentTime = currentTimeMillis
        NotificationCenter.default.post(name: .newTelemetry, object: nil, userInfo: ["telemetryData": self.telemetryArray])
        self.telemetryArray = []
    }
    
    func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            let decryptedData = self?.decryptData(data: data ?? Data())
            
            guard let gt7data = Gt7Data(data: decryptedData ?? Data()) else {
                print("Invalid data...")
                
                self?.receive(on: connection)
                
                return
            }
            
            if gt7data.isPaused == false {
                self?.triggerNewDataEvent(gt7data: gt7data)
            }
            
            self?.receive(on: connection)
        }
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
