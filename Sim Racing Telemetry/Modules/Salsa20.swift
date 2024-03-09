//
//  Salsa20.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import Foundation
import Clibsodium

class Salsa20 {
    public static func xor(data: Data, nonce: Data, secretKey: Data) -> Data?  {
        let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let noncePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: nonce.count)
        let keyPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: secretKey.count)
        
        let dataLength = data.count
        
        data.copyBytes(to: dataPointer, count: dataLength)
        nonce.copyBytes(to: noncePointer, count: nonce.count)
        secretKey.copyBytes(to: keyPointer, count: secretKey.count)
        
        Clibsodium.crypto_stream_salsa20_xor(dataPointer, dataPointer, UInt64(dataLength), noncePointer, keyPointer)
        
        let returnData = Data(bytes: dataPointer, count: dataLength)
        
        dataPointer.deinitialize(count: dataLength)
        dataPointer.deallocate()
        
        keyPointer.deinitialize(count: secretKey.count)
        keyPointer.deallocate()
        
        noncePointer.deinitialize(count: nonce.count)
        noncePointer.deallocate()
        
        return returnData
    }
}

