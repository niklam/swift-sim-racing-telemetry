//
//  TelemetryData.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 12.3.2024.
//

import Foundation

class TelemetryData: Identifiable, Codable {
    /// Package ID. Incremented by one for each package.
    var packageId: Int = 0
    
    /// Package arrival time as TimeInterval
    var packageTime: TimeInterval? = 0
    
    /// Best lap time in MS
    var lapTimeFastestMs: Int = 0
    
    /// Latest lap time in MS
    var lapTimeLastMs: Int = 0
    
    /// How many laps the race has in total, 0 for Time-Trials.
    var totalNumberOfLaps: Int = 0
    
    /// Number of the current lap. 0 prior to going over starting line.
    var currentLapNumber: Int = 0
    
    /// The gear car currently is on. -1 = Neutral, 0 = Reverse
    var currentGear: Int = 0
    
    /// Suggested gear for the next corner. 15 when there is no suggested gear.
    var suggestedGear: Int = 0
    
    /// Max gas capacity for the current car.
    /// Will be 100 for most cars, 5 for karts, 0 for electric cars
    var fuelCapacity: Float = 0
    
    /// Gas level for the current car (in liters, from 0 to Fuel Capacity).
    /// Note: This may change from 0 when regenerative braking with electric cars, check accordingly with Fuel Capacity.
    var currentFuelLeft: Float = 0
    
    /// Turbo boost. Value below 1.0 is below 0 ingame, so 2.0 = 1 x 100kPa
    var boost: Float = 0
    
    /// Current time of day on the track.
    var timeOnTrack: TimeInterval = 0
    
    /// Position in race. Not available for GT7
    var racePosition: Int = 0
    
    /// Starting position for the race.. Only available before race start, -1 after race start.
    var gridPosition: Int = 0
    
    /// Number of cars in the race before the race has started. -1 after the race has started.
    var gridSize: Int = 0
    
    /// ID of the car.
    var carId: Int = 0
    
    /// Current speed in m/s. Always positive, even when reversing.
    var carSpeed: Float = 0
    
    /// Percentage of throttle pedal applied.
    var throttle: Float = 0
    
    /// Percentage of brake pedal applied.
    var brake: Float = 0
    
    /// Engine RPM
    var rpm: Float = 0
    
    /// In RPM, indicates RPM when rev indicator starts flashing.
    var rpmRevWarning: Int = 0
    
    /// In RPM, indicates RPM when rev limiter is hit.
    var rpmRevLimiter: Int = 0
    
    /// Calculated theoretical top speed of the car
    var carTopSpeedCalculated: Int = 0
    
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
    
    var gearRatios: [Float] = []
    
    /// Cars current location in the physical world
    var location: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
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
}
