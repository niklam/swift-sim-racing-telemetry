//
//  ContentView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import SwiftUI
import Charts
import Network

struct RaceView: View {
    let telemetryDataNotificationPublisher = NotificationCenter.default.publisher(for: .telemetryDataUpdated)
    
    let visibleTickCount = 600
    
    @StateObject var drivingSession: DrivingSession
    
    var telemetryRaw: [Gt7Data] {
        if drivingSession.telemetry.count > 0 {
            return drivingSession.telemetry
        }
        
        return []
    }
    
    var telemetry: [Gt7Data] {
        if telemetryRaw.count > visibleTickCount {
            return telemetryRaw.suffix(visibleTickCount)
        }
        
        var firstPackageId: Int {
            if telemetryRaw.count == 0 {
                return 0
            }
            
            return telemetryRaw[0].packageId
        }
        
        var array: [Gt7Data] = []
        let fillInItemsNeeded = visibleTickCount - telemetryRaw.count
        
        if fillInItemsNeeded > 0 {
            for i in 1...fillInItemsNeeded {
                let data = Gt7Data()
                // 100 - 600 + 1
                data.packageId = firstPackageId - fillInItemsNeeded + i
                array.append(data)
            }
        }
        
        array.append(contentsOf: telemetryRaw)
        
        return array
    }
    
    var latestData: Gt7Data {
        return telemetry.last!
    }
    
    var minValue: Int {
        return Int(telemetry[0].packageId)
    }
    
    var maxValue: Int {
        return Int(telemetry[telemetry.count-1].packageId)
    }

    var body: some View {
        VStack {
            HStack {
                Text("Time on track: ")
                TimeDisplay(timeInterval: latestData.timeOnTrack)
            }
            HStack {
                Text("Fastest lap: ")
                LapTimeDisplay(milliseconds: drivingSession.lapFastest.lapTime)
                    .foregroundColor(.purple)
                
                Text("Last lap: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: drivingSession.lapLast.lapTime)
                    .foregroundColor(drivingSession.lapLast.lapTime <= drivingSession.lapFastest.lapTime ? .purple : .black)
                
                Text("Calculated time: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: Int(round(Float(drivingSession.lapLast.telemetry.count) * Float(1000/119.931234))))
            }
            VStack {
                Text(String(format: "%0.0f km/h", round(telemetry.last?.carSpeed ?? 0)))
                    .bold()
                    .font(.largeTitle)
            }
            VStack {
                Text("Throttle and Brake").bold()
                Chart {
                    ForEach(self.telemetry) {
                        LineMark(x: .value("Tick", $0.packageId), y: .value("Throttle", $0.throttle),
                                 series: .value("Series", 1)
                        )
                        .foregroundStyle(.green)
                        
                        LineMark(x: .value("Tick", $0.packageId), y: .value("Brake", $0.brake),
                                 series: .value("Series", 2)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .chartYAxis {
                    AxisMarks(
                        values: [0, 50, 100]
                    ) {
                        AxisValueLabel(format: Decimal.FormatStyle.Percent.percent.scale(1))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    }
                    
                    AxisMarks(
                        values: [25, 75]
                    ) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2,4]))
                    }
                }
                .chartYScale(domain: [0, 100])
                .chartXAxis(.hidden)
                .chartXScale(domain: [minValue, maxValue], type: .linear)
            }
            .padding(20)
        }
        .frame(minWidth: 600, idealWidth: 800, minHeight: 370, idealHeight: 400)
        .onReceive(telemetryDataNotificationPublisher, perform: { notification in
            guard let telemetryData = notification.userInfo?["telemetryData"] as? [Gt7Data] else {
                return
            }
            
            drivingSession.telemetry.append(contentsOf: telemetryData)
        })
    }

//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
}

//#Preview {
//    ContentView(lastLap: Lap.sampleLap, fastestLap: Lap())
//        .modelContainer(for: Item.self, inMemory: true)
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RaceView(drivingSession: DrivingSession.sampleSession1)
    }
}
