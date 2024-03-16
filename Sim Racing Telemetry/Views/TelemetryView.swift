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
    @EnvironmentObject var drivingSession: DrivingSession
//    @StateObject var drivingSession: DrivingSession
    
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    private var lap: Lap {
        return drivingSession.lapLast
    }
    
    private var minValue: Int {
        return lap.telemetry.first?.packageId ?? 0
    }
    
    private var maxValue: Int {
        return lap.telemetry.last?.packageId ?? 100
    }
    
    private var _visibleTicks: Int?
    
    private var visibleTicks: Int {
        get {
            if let ticks = _visibleTicks {
                return ticks
            } else {
                return max(lap.telemetry.count, 1000)
            }
        }
        set {
            _visibleTicks = newValue
        }
    }
    
    private var calculatedLapTime: Int {
        let startTime: TimeInterval = lap.telemetry.first?.packageTime ?? 0
        let endTime: TimeInterval = lap.telemetry.last?.packageTime ?? 0
        
        let difference = Int((endTime - startTime) * 1000)
        
        return difference
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp)")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            HStack {
                Text("Lap \(drivingSession.currentlyOnLap)")
                    .font(.title)
            }
            HStack {
                Text("Last lap: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: drivingSession.lapLast.lapTime)
                    .foregroundColor(drivingSession.lapLast.lapTime <= drivingSession.lapFastest.lapTime ? .purple : .black)
                
                Text("Fastest lap: ")
                LapTimeDisplay(milliseconds: drivingSession.lapFastest.lapTime)
                    .foregroundColor(.purple)
                
//                Text("Calculated time: ")
//                    .padding(.leading)
//                LapTimeDisplay(milliseconds: Int(round(Float(drivingSession.lapLast.telemetry.count) * Float(1000/119.931234))))
                LapTimeDisplay(milliseconds: calculatedLapTime)
            }
            
            VStack {
                Text("Throttle and Break").bold()
                Chart {
                    ForEach(0..<lap.telemetry.count, id: \.self) { index in
                        let item = self.lap.telemetry[index]
                        
                        LineMark(x: .value("Tick", index), y: .value("Throttle", item.throttle),
                                 series: .value("Series", 1)
                        )
                        .foregroundStyle(by: .value("Value", "Throttle"))
                        
                        LineMark(x: .value("Tick", index), y: .value("Brake", item.brake),
                                 series: .value("Series", 2)
                        )
                        .foregroundStyle(by: .value("Value", "Brake"))
                    }
                }
                .chartForegroundStyleScale([
                    "Throttle": .green,
                    "Brake": .red
                ]).chartYAxis {
                    AxisMarks(
                        values: [0, 50, 100]
                    ) {
//                        AxisValueLabel(format: Decimal.FormatStyle.Percent.percent.scale(1))
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    }
                    
                    AxisMarks(
                        values: [25, 75]
                    ) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2,4]))
                    }
                }
                .chartYScale(domain: [0, 100])
//                .chartXAxis(.hidden)
                .chartXScale(domain: [0, lap.telemetry.count], type: .linear)
                .chartXVisibleDomain(length: visibleTicks)
                .chartScrollableAxes(.horizontal)
            }
            .padding(20)
            
            VStack {
                Text("Speed").bold()
                Chart {
                    ForEach(0..<lap.telemetry.count, id: \.self) { index in
                        let item = self.lap.telemetry[index]
                        
                        LineMark(x: .value("Tick", index), y: .value("Speed", item.carSpeed),
                                 series: .value("Series", 1)
                        )
                        .foregroundStyle(by: .value("Value", "Speed"))
                    }
                }
                .chartForegroundStyleScale([
                    "Speed": .green
                ])
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic){
                        axis in
                        AxisTick()
                        AxisGridLine()
//                        AxisValueLabel()
                    }
                    AxisMarks(position: .trailing, values: .automatic){
                        axis in
                        AxisTick()
                        AxisGridLine()
//                        AxisValueLabel()
                    }
                }
//                .chartYScale(domain: [0, lap.telemetry.first?.rpmRevLimiter ?? 10000])
//                .chartXAxis(.hidden)
                .chartXScale(domain: [0, lap.telemetry.count], type: .linear)
                .chartXVisibleDomain(length: visibleTicks)
                .chartScrollableAxes(.horizontal)
            }
            .padding(20)
            
            
            VStack {
                Text("RPM").bold()
                Chart {
                    ForEach(0..<lap.telemetry.count, id: \.self) { index in
                        let item = self.lap.telemetry[index]
                        
                        LineMark(x: .value("Tick", index), y: .value("RPM", item.rpm),
                                 series: .value("Series", 2)
                        )
                        .foregroundStyle(by: .value("Value", "RPM"))
                    }
                }
                .chartForegroundStyleScale([
                    "RPM": .red
                ])
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic){
                        axis in
                        AxisTick()
                        AxisGridLine()
//                        AxisValueLabel()
                    }
                    AxisMarks(position: .trailing, values: .automatic){
                        axis in
                        AxisTick()
                        AxisGridLine()
//                        AxisValueLabel()
                    }
                }
//                .chartYScale(domain: [0, lap.telemetry.first?.rpmRevLimiter ?? 10000])
//                .chartXAxis(.hidden)
                .chartXScale(domain: [0, lap.telemetry.count], type: .linear)
                .chartXVisibleDomain(length: visibleTicks)
//                .chartScrollableAxes(.horizontal)
            }
            .padding(20)
        }
//        .onChange(of: drivingSession) { oldValue, newValue in
//            addItem(lap: drivingSession.lapLast)
//        }
    }
    
    private func addItem(/*lap: Lap*/) {
        withAnimation {
            let newItem = Item(timestamp: Date()/*, lap: lap*/)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
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
