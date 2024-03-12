//
//  HostIpAddress.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import Foundation

class HostInputViewModel: ObservableObject {
    @Published var host: String {
        didSet {
            saveIpAddress(host)
        }
    }
    
    init() {
        host = UserDefaults.standard.string(forKey: "gt7_host") ?? ""
    }
    
    private func saveIpAddress(_ address: String) {
        UserDefaults.standard.set(address, forKey: "gt7_host")
    }
    
    private func loadIpAddress() -> String? {
        UserDefaults.standard.string(forKey: "gt7_host")
    }
}
