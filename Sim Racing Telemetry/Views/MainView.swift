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
    @StateObject private var viewModel = HostInputViewModel()
    
    @FocusState private var isStartListeningFocused: Bool
    
    @State private var listener: TelemetryReader?
    
    @State private var isReceivingTelemetry: Bool = false
    @State private var lastTelemetryReceived: TimeInterval = 0
    @State private var connectionStatusTimer: Timer?
    
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
                Circle()
                    .fill(self.isReceivingTelemetry ? .green : .red)
                    .frame(width: 20, height: 20)
            }
            .padding(.top)
            
            VStack {
                Button(action: {
                    listeningButtonAction()
                }) {
                    Text(isConnected ? "Stop session" : "Start session")
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
//            openWindowRaceView()
//            openWindowTelemetryView()
            
            connectionStatusTimer?.invalidate()
            connectionStatusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let now = Date().timeIntervalSince1970
                
                self.isReceivingTelemetry = (now - self.lastTelemetryReceived < 1)
            }
        }
        .onDisappear {
            connectionStatusTimer?.invalidate()
        }
        .onReceive(telemetryDataNotificationPublisher, perform: { notification in
            DispatchQueue.main.async {
                
                guard let telemetryData = notification.userInfo?["telemetryDataArray"] as? [TelemetryData] else {
                    return
                }
                
                if telemetryData.count > 0 {
                    self.lastTelemetryReceived = Date().timeIntervalSince1970
                }
                
                drivingSession.addTelemetry(telemetryData, onLapCompletion: { drivingSession, lapNumber in
                    if lapNumber > 0 {
                        self.telemetryViewDrivingSession.clone(drivingSession: drivingSession)
                        DrivingSession.saveToJSONFile(objects: drivingSession)
                    }
                })
            }
        })
    }
    
    func listeningButtonAction() {
        // Toggle the connection state
        self.isConnected.toggle()
        
        if isConnected == false {
            self.listener?.cancel()
            preventSleep(shouldPrevent: false)
        } else {
            self.drivingSession.reset()
            
            if (self.listener == nil) {
                self.listener = Gt7TelemetryReader(host: NWEndpoint.Host(viewModel.host), telemetryInterval: 100)
//                self.listener = SampleTelemetryReader()
            }
            
            self.listener?.fetch()
            preventSleep(shouldPrevent: true)
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
        newWindow.center()
//        newWindow.setFrameAutosaveName("RacingView")
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false
        newWindow.title = "Racing view"
        
        NSApp.activate(ignoringOtherApps: true)
    }

    func openWindowTelemetryView() {
        let contentView = TelemetryView()
            .modelContainer(for: Item.self, inMemory: true)
            .environmentObject(telemetryViewDrivingSession)
        
        // Create the window and set the content view.
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        newWindow.center()
//        newWindow.setFrameAutosaveName("TelemetryAnalyzer")
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
        newWindow.isReleasedWhenClosed = false
        newWindow.title = "Telemetry analyzer"
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func preventSleep(shouldPrevent: Bool) {
        if shouldPrevent {
            // Start caffeinate process to prevent sleep
            let process = Process()
            process.launchPath = "/usr/bin/caffeinate"
            process.arguments = ["-di"]
            process.launch()
        } else {
            // Kill the caffeinate process to allow sleep again
            let killProcess = Process()
            killProcess.launchPath = "/usr/bin/killall"
            killProcess.arguments = ["caffeinate"]
            killProcess.launch()
        }
    }

}


#Preview {
    MainView()
}
