//
//  LapTimeDisplay.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 9.3.2024.
//

import SwiftUI

struct LapTimeDisplay: View {
    let milliseconds: Int
    
    var formattedTime: String {
        guard milliseconds > 0 else {
            return "--:--.---"
        }
        
        let totalSeconds = Double(milliseconds) / 1000
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let ms = milliseconds % 1000
        
        return String(format: "%02d:%02d.%03d", minutes, seconds, ms)
    }
    
    var body: some View {
        Text(formattedTime)
    }
}

struct LapTimeDisplay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LapTimeDisplay(milliseconds: 12345600) // Example with valid milliseconds
            LapTimeDisplay(milliseconds: 123456) // Example with valid milliseconds
            LapTimeDisplay(milliseconds: 0)      // Example with 0 milliseconds
            LapTimeDisplay(milliseconds: -100)   // Example with negative milliseconds
        }
    }
}

