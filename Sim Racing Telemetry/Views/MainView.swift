//
//  MainView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import SwiftUI
import Network

struct MainView: View {
    let telemetryDataNotificationPublisher = NotificationCenter.default.publisher(for: .newTelemetry)
    
    @StateObject private var drivingSession: DrivingSession = DrivingSession()
    @StateObject private var telemetryViewDrivingSession: DrivingSession = DrivingSession()
    
    @State private var isConnected = false
    @State var packagesReveivedCount = 0
//    var host: NWEndpoint.Host = "192.168.10.140"
    @StateObject private var viewModel = HostInputViewModel()
    
    @FocusState private var isStartListeningFocused: Bool
    
//    var heartbeat: HeartbeatManager = HeartbeatManager(host: "localhost")
    
    var listener: TelemetryReader = SampleTelemetryReader()
    
    var body: some View {
        VStack {
            Text("Sim Racing Telemetry for GT7")
                .font(.title)
            
            HStack {
                Text("PlayStation IP:")
                TextField("Enter PlayStation's IP", text: $viewModel.host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            VStack {
                Button(action: {
                    listeningButtonAction()
                }) {
                    Text(isConnected ? "Stop listening" : "Start listening")
                }
                .focused($isStartListeningFocused)
            }
            .padding(.vertical)
            
            Button(action: {
                openWindowRaceView()
            }, label: {
                Text("Racing View")
                    .frame(minWidth: 150)
            })
            
            Button(action: {
                openWindowTelemetryView()
            }, label: {
                Text("Telemetry Analyzer")
                    .frame(minWidth: 150)
            })
        }
        .padding()
        .frame(minWidth: 200, idealWidth: 800, idealHeight: 800)
        .onAppear {
            isStartListeningFocused = true
            openWindowRaceView()
            openWindowTelemetryView()
        }
        .onReceive(telemetryDataNotificationPublisher, perform: { notification in
            DispatchQueue.main.async {
//                myDebugPrint("Received telemetry")
                
                guard let telemetryData = notification.userInfo?["telemetryDataArray"] as? [TelemetryData] else {
                    return
                }
                
                
            }
        })
    }
    
    func listeningButtonAction() {
        // Toggle the connection state
        self.isConnected.toggle()
        
        if isConnected == false {
//            self.heartbeat.stopHeartbeat()
            self.listener.cancel()
        } else {
            
//            self.listener.host = NWEndpoint.Host(self.viewModel.host)
//            self.listener.listen()
            self.listener.fetch()
            
//            self.heartbeat.host = self.viewModel.host
//            self.heartbeat.startHeartbeat()
        }
    }
    
    func openWindowRaceView() {
        let contentView = RaceView()
            .environmentObject(drivingSession)
        
        // Create the window and set the content view.
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
//        newWindow.center()
//        newWindow.setFrameAutosaveName("RacingView")
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false
        newWindow.title = "Racing view"
        
        NSApp.activate(ignoringOtherApps: true)
    }

    func openWindowTelemetryView() {
        let contentView = TelemetryView()
            .environmentObject(telemetryViewDrivingSession)
        
        // Create the window and set the content view.
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
//        newWindow.center()
//        newWindow.setFrameAutosaveName("TelemetryAnalyzer")
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false
        newWindow.title = "Telemetry analyzer"
        
        NSApp.activate(ignoringOtherApps: true)
    }
}


#Preview {
    MainView()
}
