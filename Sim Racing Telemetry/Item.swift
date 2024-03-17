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
    var sessionUuid: UUID
    
    init(sessionUuid: UUID) {
        self.sessionUuid = sessionUuid
    }
}
