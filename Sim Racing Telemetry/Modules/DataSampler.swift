//
//  DataSampler.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 23.3.2024.
//

import Foundation

enum ThrottleBrakeState {
    case onThrottle
    case onBrake
    case coasting
}

struct DataPoint {
    let value: Double
}

struct CoordinateDataPoint {
    let coordinate: SIMD3<Float>
    let state: ThrottleBrakeState
}


struct DataSampler {
    static public func sampleDataPoints(from coordinates: [CoordinateDataPoint], graphWidth: Int) -> [CoordinateDataPoint] {
        let totalDataPoints = coordinates.count
        let pointsPerPixel = Double(totalDataPoints) / Double(graphWidth)
        var dataPoints: [CoordinateDataPoint] = [coordinates[0]]
        
        for index in stride(from: 0, to: totalDataPoints, by: Int(pointsPerPixel)) {
            let endIndex = min(index + Int(pointsPerPixel), totalDataPoints)
            let range = index..<endIndex
            
            let ticksOnThrottle = coordinates[range].reduce(0) { $0 + ($1.state == ThrottleBrakeState.onThrottle ? 1 : 0) } / Double(range.count)
            let ticksOnBrake = coordinates[range].reduce(0) { $0 + ($1.state == ThrottleBrakeState.onBrake ? 1 : 0) } / Double(range.count)
            
            var averageState: ThrottleBrakeState = .onThrottle
            
            if ticksOnBrake >= ticksOnThrottle {
                averageState = .onBrake
            }
            
            if ticksOnBrake + ticksOnThrottle < 0.5 {
                averageState = .coasting
            }
            
//            let averageValue = inputDataPoints[range].reduce(0) { $0 + $1.value } / Double(range.count)
            dataPoints.append(CoordinateDataPoint(coordinate: coordinates[endIndex-1].coordinate, state: averageState))
        }
        
        debugPrint("Number of dataPoints: ", dataPoints.count)
        
        return dataPoints
    }
    
    static public func sampleDataPoints(from floats: [Float], graphWidth: Int) -> [DataPoint] {
        let dataPoints: [DataPoint] = floats.map { DataPoint(value: Double($0)) }
        
        return self.sampleDataPoints(from: dataPoints, graphWidth: graphWidth)
    }
    
    static public func sampleDataPoints(from inputDataPoints: [DataPoint], graphWidth: Int) -> [DataPoint] {
        debugPrint(graphWidth)
        
        let totalDataPoints = inputDataPoints.count
        let pointsPerPixel = Double(totalDataPoints) / Double(graphWidth)
        var dataPoints: [DataPoint] = []
        
        for index in stride(from: 0, to: totalDataPoints, by: Int(pointsPerPixel)) {
            let endIndex = min(index + Int(pointsPerPixel), totalDataPoints)
            let range = index..<endIndex
            let averageValue = inputDataPoints[range].reduce(0) { $0 + $1.value } / Double(range.count)
            dataPoints.append(DataPoint(value: averageValue))
        }
        
        debugPrint("Number of dataPoints: ", dataPoints.count)
        
        return dataPoints
    }
}
