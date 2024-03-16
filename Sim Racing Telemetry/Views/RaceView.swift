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
    @EnvironmentObject var drivingSession: DrivingSession
    
    let visibleTickCount = 600
    
    var visibleTelemetry: [TelemetryData] {
        if drivingSession.telemetry.count > 0 {
            return drivingSession.telemetry.suffix(visibleTickCount)
        }
        
        return []
    }
    
    var latestData: TelemetryData {
        return drivingSession.telemetry.last ?? TelemetryData()
    }
    
    var minValue: Int {
        return maxValue - visibleTickCount
    }
    
    var maxValue: Int {
        let count = visibleTelemetry.count
        
        return Int(count == 0 ? 1 : visibleTelemetry[count-1].packageId)
    }

    var body: some View {
        
        VStack {
            HStack {
                Text("Time on track: ")
                TimeDisplay(timeInterval: latestData.timeOnTrack)
                
                Text("Currently on lap: \(latestData.currentLapNumber)")
                
                Text("PackageId: \(latestData.packageId)")
            }
            
            HStack {
                Text("Last lap: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: drivingSession.lapLast.lapTime)
                    .foregroundColor(drivingSession.lapLast.lapTime <= drivingSession.lapFastest.lapTime ? .purple : .black)
                
                Text("Fastest lap: ")
                LapTimeDisplay(milliseconds: drivingSession.lapFastest.lapTime)
                    .foregroundColor(.purple)
                
                Text("Calculated time: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: Int(round(Float(drivingSession.lapLast.telemetry.count) * Float(1000/119.931234))))
            }
            
            VStack {
                Text(String(format: "%0.0f km/h", round(latestData.carSpeed)))
                    .bold()
                    .font(.largeTitle)
            }
            
            VStack {
                Text("Throttle and Brake").bold()
                Chart {
                    ForEach(drivingSession.telemetry.suffix(visibleTickCount)) {
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
    }
}

//#Preview {
//    ContentView(lastLap: Lap.sampleLap, fastestLap: Lap())
//        .modelContainer(for: Item.self, inMemory: true)
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = {
            myDebugPrint("--- Init Preview ---")
        }
        RaceView()
            .environmentObject(DrivingSession.sampleSession1)
    }
}
