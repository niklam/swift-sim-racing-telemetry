//
//  Sim_Racing_TelemetryApp.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import SwiftUI
import SwiftData
import Network
import Combine

@main
struct Sim_Racing_TelemetryApp: App {
    var host: NWEndpoint.Host = "192.168.10.140"
    var port: NWEndpoint.Port = 33740
    @State private var dataCollection: [Gt7Data] = []
    
    let telemetryDataNotificationPublisher = NotificationCenter.default.publisher(for: .telemetryDataUpdated)
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(throttleData: dataCollection)
                .onReceive(telemetryDataNotificationPublisher, perform: { notification in
                    guard let telemetryData = notification.userInfo?["telemetryData"] as? [Gt7Data] else {
                        return
                    }
                    
                    dataCollection.append(contentsOf: telemetryData)
                })
                .onAppear() {
                    let listener = UdpReader(host: host)
                    listener.listen()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
