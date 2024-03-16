//
//  Item.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
//    var lap: Lap
    
    init(timestamp: Date/*, lap: Lap*/) {
        self.timestamp = timestamp
//        self.lap = lap
    }
}
