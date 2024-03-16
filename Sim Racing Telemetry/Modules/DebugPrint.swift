//
//  DebugPrint.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 15.3.2024.
//

import Foundation

func myDebugPrint(_ output: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSS"

    let currentTime = Date()
    let currentTimeString = dateFormatter.string(from: currentTime)

    print(String(format: "%@ %@", currentTimeString, output))
}
