//
//  UdpReader.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import Foundation
import Network
import Sodium
import Clibsodium

public class UdpReader {
    var connection: NWConnection?
    var listener: NWListener?
    var host: NWEndpoint.Host
    var hbPort: NWEndpoint.Port
    var udpPort: NWEndpoint.Port
    var packageCollection: [Gt7Data] = []
    var prevPackageSentTime: Int = 0
    
    init(host: NWEndpoint.Host, udpPort: NWEndpoint.Port = 33740, hbPort: NWEndpoint.Port = 33739) {
        self.host = host
        self.udpPort = udpPort
        self.hbPort = hbPort
    }
    
    public func listen() {
        print("Starting to listen to \(self.host):\(self.udpPort)")
        
        /**/
        var hexString = "5d8c f3d8 0a4b 583c b06c 7bac 551a f5c3 7e0c 487d 6666 dbb4 3e40 bbce 827d 0db1 eecb 0104 5244 ad48 221d e780 8465 7a14 7a1d c708 3cba e96e 8eb0 4638 f768 6481 449b 90ea fa8d a88f 8750 6f68 999d 90ed b302 50a2 3dfc f431 4ff5 0cef 6d57 7f97 07f7 8508 796a 1dfe 9d1b 0732 1a41 1428 f787 33f5 d0b9 c066 73ba d845 0746 738f 88fe 75f5 1fd8 f826 bfa2 5e95 e3fa e8ed a11d 158f e89d c269 ef89 f7c9 fa3b 280d d250 05ec e69f 16cd afbb 2d4b eb79 ed83 a94e 4d28 a68b 9f40 3937 ab35 3ac4 53f5 16d9 2549 f900 8465 779c 0ad5 f29d 9ac5 c128 3ff7 62df 5f07 0975 606e a40f 201c 0316 94ba 0c30 63c3 db15 42b8 9431 ccbf f217 4867 4d54 7222 7e99 e99c 585b c3f2 8b24 fc12 9788 0daa 4c26 efc0 ca10 611a 7afe 97e0 4e89 1721 8ad6 7dfd bbe9 fa9c 719b 7e23 374c 048b"
        
        let sodium = Sodium()
        let dataBytes = sodium.utils.hex2bin(hexString, ignore: " ")!
        
        let ddata = decryptData(data: Data(bytes: dataBytes, count: dataBytes.count))
        
        let gt7data = Gt7Data(data: ddata!)
        
        self.triggerNewDataEvent(gt7data: gt7data!)
        return
        /**/
        
        let listener = try! NWListener(using: .udp, on: self.udpPort)
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Listener ready on \(self.udpPort)")
            case .failed(let error):
                print("Listener failed with error: \(error)")
            default:
                break
            }
        }
        
        sendHeartbeat()

        listener.newConnectionHandler = { newConnection in
            newConnection.start(queue: .main)
            self.receive(on: newConnection)
        }

        // Start the listener on the main queue
        listener.start(queue: .main)
    }
    
    /// Triggers the telemetryDataUpdated notification
    /// Note, that it's only triggered once every 100 ms, no matter how often it's called. If the notification
    /// is not triggered, the telemetry data is collected, and then sent together with other telemetry once
    /// the notification actually triggers.
    func triggerNewDataEvent(gt7data: Gt7Data) {
        self.packageCollection.append(gt7data)
        let currentTimeMillis = Int(Date().timeIntervalSince1970 * 1000)
        
        // Only send the telemetry data 10 times per second. I did it this way
        // so that prevPackageSentTime can start as 0.
        if prevPackageSentTime - currentTimeMillis < -100 {
            prevPackageSentTime = currentTimeMillis
            NotificationCenter.default.post(name: .telemetryDataUpdated, object: nil, userInfo: ["telemetryData": packageCollection])
            packageCollection = []
        }
    }
    
    func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] (data, context, isComplete, error) in
            let decryptedData = self?.decryptData(data: data ?? Data())
            
            guard let gt7data = Gt7Data(data: decryptedData ?? Data()) else {
                print("Invalid data...")
                
                self?.receive(on: connection)
                
                return
            }
            
            self?.triggerNewDataEvent(gt7data: gt7data)
            
            if gt7data.packageId % 120 == 0 {
                self?.sendHeartbeat()
            }
            
            self?.receive(on: connection)
        }
    }

    func sendHeartbeat() {
        let connection = NWConnection(host: self.host, port: self.hbPort, using: .udp)

        connection.start(queue: .global())

        let sendContent = "A"
        if let sendData = sendContent.data(using: .utf8) {
            connection.send(content: sendData, completion: .contentProcessed({ error in
                if let error = error {
                    print("Error occurred while sending data: \(error)")
                } else {
                    print("Data was sent successfully.")
                }

                // Optionally, you might want to close the connection after sending
                connection.cancel()
            }))
        } else {
            print("Failed to encode string to data.")
        }
    }

    
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

extension Notification.Name {
    static let telemetryDataUpdated = Notification.Name("telemetryDataUpdated")
}

