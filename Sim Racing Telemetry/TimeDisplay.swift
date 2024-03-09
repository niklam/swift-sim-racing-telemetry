//
//  TimeDisplay.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 9.3.2024.
//

import SwiftUI

struct TimeDisplay: View {
    let timeInterval: TimeInterval
    
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: timeInterval) ?? "N/A"
    }
    
    var body: some View {
        Text(formattedTime)
    }
}

struct TimeDisplay_Previews: PreviewProvider {
    static var previews: some View {
        // Example usage with a TimeInterval of 3661 seconds (1 hour and 1 minute)
        TimeDisplay(timeInterval: 3661)
    }
}

