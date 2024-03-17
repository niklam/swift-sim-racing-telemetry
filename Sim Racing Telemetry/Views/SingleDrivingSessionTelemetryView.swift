//
//  SingleDrivingSessionTelemetry.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 17.3.2024.
//

import SwiftUI
import Charts

struct SingleDrivingSessionTelemetryView: View {
    var drivingSession: DrivingSession
    
    private var lap: Lap {
        return drivingSession.laps.first ?? Lap()
    }
    
    private var minValue: Int {
        return lap.telemetry.first?.packageId ?? 0
    }
    
    private var maxValue: Int {
        return lap.telemetry.last?.packageId ?? 100
    }
    
    private var visibleTicks: Int {
        get {
            return max(lap.telemetry.count, 1000)
        }
    }
    
    private var calculatedLapTime: Int {
        let startTime: TimeInterval = lap.telemetry.first?.packageTime ?? 0
        let endTime: TimeInterval = lap.telemetry.last?.packageTime ?? 0
        
        let difference = Int((endTime - startTime) * 1000)
        
        return difference
    }
    
    private var lapSelectionModel: LapSelectionModel {
        let model = LapSelectionModel()
        
        drivingSession.laps.forEach { lap in
            if lap.lapNumber == 0 || lap.lapTime == -1 {
                return
            }
            
            let isFastestLap: Bool = lap.lapTime == drivingSession.lapFastest.lapTime
            
            model.items.append(LapSelectionItem(lap: lap, isFastestLap: isFastestLap, isSelected: isFastestLap))
        }
        
        return model
    }
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text("Lap \(drivingSession.currentlyOnLap)")
                        .font(.title)
                }
                
                HStack {
                    Text("Lap time: ")
                        .padding(.leading)
                    LapTimeDisplay(milliseconds: lap.lapTime)
                    //                .foregroundColor(drivingSession.lapLast.lapTime <= drivingSession.lapFastest.lapTime ? .purple : .black)
                    
                    Text("Fastest lap: ")
                    LapTimeDisplay(milliseconds: drivingSession.lapFastest.lapTime)
                        .foregroundColor(.purple)
                    
                    //                Text("Calculated time: ")
                    //                    .padding(.leading)
                    //                LapTimeDisplay(milliseconds: Int(round(Float(drivingSession.lapLast.telemetry.count) * Float(1000/119.931234))))
                    //            LapTimeDisplay(milliseconds: calculatedLapTime)
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
                .frame(minHeight: 200)
                
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
                .frame(minHeight: 200)
                
                
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
                .frame(minHeight: 200)
            }
            
            VStack {
                LapSelectionCheckboxListView(viewModel: lapSelectionModel)
            }
            .frame(width: 200)
        }
    }
}

#Preview {
    SingleDrivingSessionTelemetryView(drivingSession: DrivingSession.sampleSession1)
}

struct LapSelectionItem: Identifiable {
    let id: UUID = UUID()
    var lap: Lap
    var name: String
    var isFastestLap: Bool
    var isSelected: Bool
    
    init(lap: Lap, isFastestLap: Bool = false, isSelected: Bool = false) {
        self.lap = lap
        self.isFastestLap = isFastestLap
        self.isSelected = isSelected
        self.name = String(format: "Lap %d", lap.lapNumber)
    }
}

class LapSelectionModel: ObservableObject {
    @Published var items: [LapSelectionItem] = []
    
    func toggleSelection(for itemId: UUID) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].isSelected.toggle()
        }
    }
}

struct LapSelectionCheckboxListView: View {
    @ObservedObject var viewModel = LapSelectionModel()

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                LapSelectionCheckboxRow(item: item, toggleSelection: viewModel.toggleSelection)
            }
        }
    }
}

struct LapSelectionCheckboxRow: View {
    var item: LapSelectionItem
    var toggleSelection: (UUID) -> Void // Closure to toggle selection
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { item.isSelected },
            set: { _ in toggleSelection(item.id) }
        )) {
            let label = String(format: "%@%@", item.name, item.isFastestLap ? " - Fastest" : "")
            Text(label)
                .foregroundColor(item.isFastestLap ? .purple : .black)
            
            LapTimeDisplay(milliseconds: item.lap.lapTime)
                .foregroundColor(item.isFastestLap ? .purple : .gray)
        }
    }
}
