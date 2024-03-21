//
//  TelemetryView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 10.3.2024.
//

import SwiftUI
import SwiftData
import Charts
import Combine

struct TelemetryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var drivingSession: DrivingSession
    
    @Query private var items: [Item]
    
    @State private var sessions: [UUID: DrivingSession] = [:]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(Array(items.reversed().enumerated()), id: \.element.id) { index, item in
                    if let tmpSession = sessions[item.sessionUuid] {
                        NavigationLink {
                            SingleDrivingSessionTelemetryView(drivingSession: tmpSession)
                        } label: {
                            Text(tmpSession.name)
                        }
                        .contextMenu(menuItems: {
                            Button(action: {
                                self.deleteSessions(offsets: IndexSet(integer: index))
                            }, label: {
                                Image(systemName: "trash")
                                Text("Delete session")
                            })
                        })
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
//            .toolbar {
//                /*ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }*/
//            }
        } detail: {
            Text("Hello!")
        }
        .onChange(of: drivingSession, { oldValue, newValue in
            if oldValue.sessionStarted == newValue.sessionStarted {
                return
            }
                
            addItem(drivingSession: drivingSession)
        })
        .onAppear {
            let fm = FileManager.default
            let path = String(describing: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)
            debugPrint(path)
            
            do {
                let sessionMainFileRexEx = /^session\-(?<sessionId>[0-9]+)\-1\..*$/
                let items = try fm.contentsOfDirectory(atPath: path)
                
                for item in items {
                    let fileName = String("\(item)")
                    if let match = try sessionMainFileRexEx.firstMatch(in: fileName) {
                        let sessionId: String = String(describing: match.1)
                        
                        guard let drivingSession = DrivingSession.loadMultiFileSessionJson(sessionId: sessionId) else {
                            continue
                        }
                        
                        addItem(drivingSession: drivingSession)
                        sessions[drivingSession.id] = drivingSession
                    }
                }
            } catch {
                print("Couldn't read \(path)")
            }
        }
    }
    
    private func addItem(drivingSession: DrivingSession) {
        withAnimation {
            let newItem = Item(sessionUuid: drivingSession.id)
            modelContext.insert(newItem)
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

struct ZoomTelemetry: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        print("drag onChanged: \(value)")
                    })
                    .onEnded({ value in
                        print("drag onEnded: \(value)")
                    })
            )
    }
}

#Preview {
    TelemetryView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(DrivingSession.sampleSession1)
}
