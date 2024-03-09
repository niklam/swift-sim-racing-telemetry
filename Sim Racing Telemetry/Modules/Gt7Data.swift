//
//  Gt7Data.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//
//  This is based on https://www.gtplanet.net/forum/threads/gt7-is-compatible-with-motion-rig.410728/page-4#post-13799643
//  and https://github.com/Nenkai/PDTools/blob/1.0.7/PDTools.SimulatorInterface/SimulatorPacket.cs
//

import Foundation

class Gt7Data: NSObject, Identifiable {
    /// Package ID. Incremented by one for each package.
    var packageId: Int = 0
    
    /// Best lap time in MS
    var lapTimeFastestMs: Int = 0
    
    /// Latest lap time in MS
    var lapTimeLastMs: Int = 0
    
    /// How many laps the race has in total, 0 for Time-Trials.
    var totalLaps: Int16 = 0
    
    /// Number of the current lap. 0 prior to going over starting line.
    var currentLap: Int16 = 0
    
    /// The gear car currently is on. -1 = Neutral, 0 = Reverse
    var currentGear: UInt8 = 0
    
    /// Suggested gear for the next corner. 15 when there is no suggested gear.
    var suggestedGear: UInt8 = 0
    
    /// Max gas capacity for the current car.
    /// Will be 100 for most cars, 5 for karts, 0 for electric cars
    var fuelCapacity: Float = 0
    
    /// Gas level for the current car (in liters, from 0 to Fuel Capacity).
    /// Note: This may change from 0 when regenerative braking with electric cars, check accordingly with Fuel Capacity.
    var currentFuel: Float = 0
    
    /// Turbo boost. Value below 1.0 is below 0 ingame, so 2.0 = 1 x 100kPa
    var boost: Float = 0
    
    /// Current time of day on the track.
    var timeOnTrack: TimeInterval = TimeInterval()
    
    /// Starting position for the race.. Only available before race start, -1 after race start.
    var preRacePosition: Int16 = 0
    
    /// Number of cars in the race before the race has started. -1 after the race has started.
    var totalPositions: Int16 = 0
    
    /// ID of the car.
    var carId: Int32 = 0
    
    /// Current speed in m/s. Always positive, even when reversing.
    var carSpeed: Float = 0
    
    /// Percentage of throttle pedal applied.
    var throttle: Float = 0
    
    /// Percentage of brake pedal applied.
    var brake: Float = 0
    
    /// Engine RPM
    var rpm: Float = 0
    
    /// In RPM, indicates RPM when rev indicator starts flashing.
    var rpmRevWarning: UInt16 = 0
    
    /// In RPM, indicates RPM when rev limiter is hit.
    var rpmRevLimiter: UInt16 = 0
    
    /// Calculated theoretical top speed of the car
    var carTopSpeedCalculated: Int16 = 0
    
    /// Percentage of clutch pedal applied.
    var clutch: Float = 0
    
    /// How much clutch is engaged. This is likely calculated as 1 - Clutch.
    /// If clutch is not fully engaged, the Effective RPM After Clutch will be affected.
    var clutchEngaged: Float = 0
    
    /// Effective RPM After Clutch is being applied.
    var rpmAfterClutch: Float = 0
    
    /// Water temperature. Always 85.
    var waterTemp: Float = 0
    
    /// Oil temperature. Always 110.
    var oilTemp: Float = 0
    
    /// Oil pressure (Bar)
    var oilPressure: Float = 0
    
    /// Ride Height in millimeters
    var rideHeight: Float = 0
    
    /// Front Left Tire - Surface Temperature (in °C)
    var tyreFL_SurfaceTemp: Float = 0
    
    /// Front Right - Surface Temperature (in °C)
    var tyreFR_SurfaceTemp: Float = 0
    
    /// Rear Left - Surface Temperature (in °C)
    var tyreRL_SurfaceTemp: Float = 0
    
    /// Rear Right - Surface Temperature (in °C)
    var tyreRR_SurfaceTemp: Float = 0
    
    var tyreFL_Diameter: Float = 0
    var tyreFR_Diameter: Float = 0
    var tyreRL_Diameter: Float = 0
    var tyreRR_Diameter: Float = 0
    
    var tyreFL_Speed: Float = 0
    var tyreFR_Speed: Float = 0
    var tyreRL_Speed: Float = 0
    var tyreRR_Speed: Float = 0
    
    var tyreFL_SlipRatio: String = ""
    var tyreFR_SlipRatio: String = ""
    var tyreRL_SlipRatio: String = ""
    var tyreRR_SlipRatio: String = ""
    
    var suspensionFL: Float = 0
    var suspensionFR: Float = 0
    var suspensionRL: Float = 0
    var suspensionRR: Float = 0
    
    var gear1: Float = 0
    var gear2: Float = 0
    var gear3: Float = 0
    var gear4: Float = 0
    var gear5: Float = 0
    var gear6: Float = 0
    var gear7: Float = 0
    var gear8: Float = 0
    
    var position: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
    var velocity: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
    var rotation: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
    var angularVelocity: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
    
    // Additional properties based on the status byte
    var isInRace: Bool = false
    var isPaused: Bool = false
    var isLoadingOrProcessing: Bool = false
    var isInGear: Bool = false
    var hasTurbo: Bool = false
    var isRevLimiterFlashing: Bool = false
    var isHandbrakeActive: Bool = false
    var areLightsOn: Bool = false
    var isLowbeamOn: Bool = false
    var isHighbeamOn: Bool = false
    var isASMActive: Bool = false
    var isTCSActive: Bool = false
    // Bits 12-15 are unspecified
    
    override init() {
        super.init()
    }
    
    init?(data: Data) {
        guard data.count >= 296 else { return nil }

        self.packageId = Int(data.readInt32LE(at: 0x70))
        self.lapTimeFastestMs = Int(data.readInt32LE(at: 0x78))
        self.lapTimeLastMs = Int(data.readInt32LE(at: 0x7C))
        self.currentLap = data.readInt16LE(at: 0x74)
        
        let gearByte = data.readUInt8(at: 0x90)
        self.currentGear = gearByte & 0b00001111
        self.suggestedGear = gearByte >> 4
        
        self.fuelCapacity = data.readFloatLE(at: 0x48)
        self.currentFuel = data.readFloatLE(at: 0x44)
        self.boost = data.readFloatLE(at: 0x50) - 1
        
        self.tyreFL_Diameter = data.readFloatLE(at: 0xB4)
        self.tyreFR_Diameter = data.readFloatLE(at: 0xB8)
        self.tyreRL_Diameter = data.readFloatLE(at: 0xBC)
        self.tyreRR_Diameter = data.readFloatLE(at: 0xC0)
        
        self.tyreFL_Speed = abs(3.6 * self.tyreFL_Diameter * data.readFloatLE(at: 0xA4))
        self.tyreFR_Speed = abs(3.6 * self.tyreFR_Diameter * data.readFloatLE(at: 0xA8))
        self.tyreRL_Speed = abs(3.6 * self.tyreRL_Diameter * data.readFloatLE(at: 0xAC))
        self.tyreRR_Speed = abs(3.6 * self.tyreRR_Diameter * data.readFloatLE(at: 0xB0))
        
        let carSpeed = data.readFloatLE(at: 0x4C) * 3.6
        self.carSpeed = carSpeed

        // Compute tyre slip ratios if car speed is greater than 0
        if carSpeed > 0 {
            self.tyreFL_SlipRatio = String(format: "%6.2f", self.tyreFL_Speed / carSpeed)
            self.tyreFR_SlipRatio = String(format: "%6.2f", self.tyreFR_Speed / carSpeed)
            self.tyreRL_SlipRatio = String(format: "%6.2f", self.tyreRL_Speed / carSpeed)
            self.tyreRR_SlipRatio = String(format: "%6.2f", self.tyreRR_Speed / carSpeed)
        } else {
            self.tyreFL_SlipRatio = "N/A"
            self.tyreFR_SlipRatio = "N/A"
            self.tyreRL_SlipRatio = "N/A"
            self.tyreRR_SlipRatio = "N/A"
        }

        // Extract other data fields...
        self.timeOnTrack = TimeInterval(data.readInt32LE(at: 0x80) / 1000)
        self.totalLaps = data.readInt16LE(at: 0x76)
        self.preRacePosition = data.readInt16LE(at: 0x84)
        self.totalPositions = data.readInt16LE(at: 0x86)
        self.carId = data.readInt32LE(at: 0x124)
        
        // Throttle and break come in as 0...255, so we need to divide it by 2.55 to have them in range 0...100
        self.throttle = Float(data.readUInt8(at: 0x91)) / 2.55
        self.brake = Float(data.readUInt8(at: 0x92)) / 2.55
        
        self.rpm = data.readFloatLE(at: 0x3C)
        self.rpmRevWarning = data.readUInt16LE(at: 0x88)
        self.boost = data.readFloatLE(at: 0x50) - 1
        self.rpmRevLimiter = data.readUInt16LE(at: 0x8A)
        self.carTopSpeedCalculated = data.readInt16LE(at: 0x8C)
        self.clutch = data.readFloatLE(at: 0xF4)
        self.clutchEngaged = data.readFloatLE(at: 0xF8)
        self.rpmAfterClutch = data.readFloatLE(at: 0xFC)
        self.oilTemp = data.readFloatLE(at: 0x5C)
        self.waterTemp = data.readFloatLE(at: 0x58)
        self.oilPressure = data.readFloatLE(at: 0x54)
        self.rideHeight = 1000 * data.readFloatLE(at: 0x38)
        
        self.tyreFL_SurfaceTemp = data.readFloatLE(at: 0x60)
        self.tyreFR_SurfaceTemp = data.readFloatLE(at: 0x64)
        self.tyreRL_SurfaceTemp = data.readFloatLE(at: 0x68)
        self.tyreRR_SurfaceTemp = data.readFloatLE(at: 0x6C)
        
        self.suspensionFL = data.readFloatLE(at: 0xC4)
        self.suspensionFR = data.readFloatLE(at: 0xC8)
        self.suspensionRL = data.readFloatLE(at: 0xCC)
        self.suspensionRR = data.readFloatLE(at: 0xD0)
        
        self.gear1 = data.readFloatLE(at: 0x104)
        self.gear2 = data.readFloatLE(at: 0x108)
        self.gear3 = data.readFloatLE(at: 0x10C)
        self.gear4 = data.readFloatLE(at: 0x110)
        self.gear5 = data.readFloatLE(at: 0x114)
        self.gear6 = data.readFloatLE(at: 0x118)
        self.gear7 = data.readFloatLE(at: 0x11C)
        self.gear8 = data.readFloatLE(at: 0x120)
        
        self.position = SIMD3<Float>(data.readFloatLE(at: 0x04), data.readFloatLE(at: 0x08), data.readFloatLE(at: 0x0C))
        self.velocity = SIMD3<Float>(data.readFloatLE(at: 0x10), data.readFloatLE(at: 0x14), data.readFloatLE(at: 0x18))
        self.rotation = SIMD3<Float>(data.readFloatLE(at: 0x1C), data.readFloatLE(at: 0x20), data.readFloatLE(at: 0x24))
        self.angularVelocity = SIMD3<Float>(data.readFloatLE(at: 0x2C), data.readFloatLE(at: 0x30), data.readFloatLE(at: 0x34))
        
        let statusByte = data.readUInt8(at: 0x8E)

        self.isInRace = (statusByte & (1 << 0)) != 0
        self.isPaused = (statusByte & (1 << 1)) != 0
        self.isLoadingOrProcessing = (statusByte & (1 << 2)) != 0
        self.isInGear = (statusByte & (1 << 3)) != 0
        self.hasTurbo = (statusByte & (1 << 4)) != 0
        self.isRevLimiterFlashing = (statusByte & (1 << 5)) != 0
        self.isHandbrakeActive = (statusByte & (1 << 6)) != 0
        self.areLightsOn = (statusByte & (1 << 7)) != 0
        self.isLowbeamOn = (statusByte & (1 << 8)) != 0
        self.isHighbeamOn = (statusByte & (1 << 9)) != 0
        self.isASMActive = (statusByte & (1 << 10)) != 0
        self.isTCSActive = (statusByte & (1 << 11)) != 0
        // Bits 12-15 are unspecified, so we don't include them
    }
}

extension Data {
    func readInt32LE(at offset: Int) -> Int32 {
        return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self).littleEndian }
    }
    
    func readInt16LE(at offset: Int) -> Int16 {
        return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self).littleEndian }
    }
    
    func readFloatLE(at offset: Int) -> Float {
        //return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self).littleEndian }
        let bytes: UInt32 = self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
        let value: UInt32 = UInt32(littleEndian: bytes)
        return Float(bitPattern: value)
    }
    
    func readUInt8(at offset: Int) -> UInt8 {
        return self[offset]
    }
    
    func readUInt16LE(at offset: Int) -> UInt16 {
        return self.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt16.self).littleEndian }
    }
}

extension Gt7Data {
    static var sampleCollection: [Gt7Data] {
        var array: Array<Gt7Data> = []
        var change: Float = 0.0
        
        for i in 1...200 {
            let data = Gt7Data()
            data.packageId = i
            data.timeOnTrack = 50607
            data.lapTimeFastestMs = 82583
            data.lapTimeLastMs = 82729
            data.throttle = 100.0
            data.brake = 0.0
            
            if i > 2300 {
                change += 1
                data.throttle -= change
                data.brake += change
            }
            
            array.append(data)
        }
        
        return array
    }
}
