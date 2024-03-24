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
    
    @State private var selectedLaps: [UUID] = []
    
    private var lapSelectionModel: LapSelectionModel {
        let model = LapSelectionModel()
        
        drivingSession.laps.forEach { lap in
            if lap.lapNumber == 0 || lap.lapTime == -1 {
                return
            }
            
            let isFastestLap: Bool = lap.lapTime == drivingSession.lapFastest.lapTime
            
            var shouldBeSelected = selectedLaps.contains(lap.id)
            
            if shouldBeSelected == false && selectedLaps.isEmpty && isFastestLap {
                shouldBeSelected = true
            }
            
            model.items.append(LapSelectionItem(lap: lap, isFastestLap: isFastestLap, isSelected: shouldBeSelected))
        }
        
        return model
    }
    
    private var lap: Lap {
        var lap = drivingSession.laps.first(where: { $0.id == selectedLaps.first })
        
        if lap == nil {
            lap = drivingSession.lapLast
        }
        
        return lap ?? Lap()
    }
    
    var body: some View {
        HStack {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack {
                        // Title
                        HStack {
                            Text("Lap \(lap.lapNumber)")
                                .font(.title)
                        }
                        
                        // Lap time
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
                        
                        // Throttle and brake
                        VStack {
                            let throttle: [DataPoint] = DataSampler.sampleDataPoints(from: lap.telemetry.map({ telemetryData in
                                DataPoint(value: Double(telemetryData.throttle))
                            }), graphWidth: Int(floor(geometry.size.width)))
                            let brake: [DataPoint] = DataSampler.sampleDataPoints(from: lap.telemetry.map({ telemetryData in
                                DataPoint(value: Double(telemetryData.brake))
                            }), graphWidth: Int(floor(geometry.size.width)))
                            
                            ThrottleAndBrakeView(throttle: throttle, brake: brake)
                        }
                        .padding(20)
                        .frame(width: geometry.size.width, height: 250)
                        
                        // Speed
                        VStack {
                            let speed: [DataPoint] = DataSampler.sampleDataPoints(from: lap.telemetry.map({ telemetryData in
                                DataPoint(value: Double(telemetryData.carSpeed))
                            }), graphWidth: Int(floor(geometry.size.width)))
                            
                            SpeedView(speed: speed)
                        }
                        .padding(20)
                        .frame(width: geometry.size.width, height: 250)
                        
                        // RPM
                        VStack {
                            let rpm: [DataPoint] = DataSampler.sampleDataPoints(from: lap.telemetry.map({ telemetryData in
                                DataPoint(value: Double(telemetryData.rpm))
                            }), graphWidth: Int(floor(geometry.size.width)))
                            
                            RpmView(rpm: rpm)
                        }
                        .padding(20)
                        .frame(width: geometry.size.width, height: 250)
                    }
                }
            }
                
            VStack {
                let coordinates: [CoordinateDataPoint] = DataSampler.sampleDataPoints(from: lap.telemetry.map({ telemetryData in
                    var state: ThrottleBrakeState = .onThrottle
                    
                    if telemetryData.brake > 0 {
                        state = .onBrake
                    }
                    
                    if telemetryData.brake == 0 && telemetryData.throttle == 0 {
                        state = .coasting
                    }
                    
                    return CoordinateDataPoint(coordinate: telemetryData.position, state: state)
                }), graphWidth: 1000)
                
                ScrollView(showsIndicators: true) {
                    ZoomableContentView(coordinates: coordinates)
                }
                
                LapSelectionCheckboxListView(viewModel: lapSelectionModel) { id, newValue in
                    if newValue == false {
                        selectedLaps.removeAll(where: { $0 == id })
                        return
                    }
                    
                    selectedLaps.removeAll()
                    
                    selectedLaps.append(id)
                    
                    selectedLaps.forEach { id in
                        let lap = drivingSession.laps.first(where: { $0.id == id })
                        
                        print("Lap \(lap?.lapNumber ?? 999)")
                    }
                }
            }
            .frame(width: 250)
        }
//        .frame(width: .infinity, height:.infinity)
    }
}

#Preview {
    SingleDrivingSessionTelemetryView(drivingSession: DrivingSession.sampleSession1)
}

struct LapSelectionItem: Identifiable {
    let id: UUID
    var lap: Lap
    var name: String
    var isFastestLap: Bool
    var isSelected: Bool
    
    init(lap: Lap, isFastestLap: Bool = false, isSelected: Bool = false) {
        self.id = lap.id
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

struct LapSelectionCheckboxListView: View {
    @ObservedObject var viewModel = LapSelectionModel()
    var onChange: (UUID, Bool) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                LapSelectionCheckboxRow(item: item, toggleSelection: viewModel.toggleSelection)
                    .onChange(of: item.isSelected) { oldValue, newValue in
                        print("Toggle \(item.id) went from \(oldValue) to \(newValue)")
                        onChange(item.id, newValue)
                    }
            }
        }
    }
}

struct ThrottleAndBrakeView: View {
    var throttle: [DataPoint]
    var brake: [DataPoint]
    
    var body: some View {
        Text("Throttle and Brake").bold()
        
        Chart {
            ForEach(0..<throttle.count, id: \.self) { i in
                LineMark(x: .value("Tick", i), y: .value("Throttle", throttle[i].value),
                         series: .value("Series", 1)
                )
                .foregroundStyle(by: .value("Value", "Throttle"))
                
                LineMark(x: .value("Tick", i), y: .value("Brake", brake[i].value),
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
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
            }
            
            AxisMarks(
                values: [25, 75]
            ) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2,4]))
            }
        }
        .chartYScale(domain: [0, 100])
        .chartXScale(domain: [0, throttle.count], type: .linear)
        .chartXVisibleDomain(length: throttle.count)
        .chartScrollableAxes(.horizontal)
    }
}

struct SpeedView: View {
    var speed: [DataPoint]
    
    var body: some View {
        Text("Throttle and Brake").bold()
        
        Chart {
            ForEach(0..<speed.count, id: \.self) { i in
                LineMark(x: .value("Tick", i), y: .value("Speed", speed[i].value),
                         series: .value("Series", 1)
                )
                .foregroundStyle(by: .value("Value", "Speed"))
            }
        }
        .chartForegroundStyleScale([
            "Speed": .green
        ])
//        .chartYAxis {
//            AxisMarks(
//                values: [0, 50, 100]
//            ) {
//                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
//            }
//            
//            AxisMarks(
//                values: [25, 75]
//            ) {
//                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2,4]))
//            }
//        }
//        .chartYScale(domain: [0, 100])
        .chartXScale(domain: [0, speed.count], type: .linear)
        .chartXVisibleDomain(length: speed.count)
        .chartScrollableAxes(.horizontal)
    }
}

struct RpmView: View {
    var rpm: [DataPoint]
    
    var body: some View {
        Text("RPM").bold()
        
        Chart {
            ForEach(0..<rpm.count, id: \.self) { i in
                LineMark(x: .value("Tick", i), y: .value("RPM", rpm[i].value),
                         series: .value("Series", 1)
                )
                .foregroundStyle(by: .value("Value", "RPM"))
            }
        }
        .chartForegroundStyleScale([
            "RPM": .red
        ])
//        .chartYAxis {
//            AxisMarks(
//                values: [0, 50, 100]
//            ) {
//                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
//            }
//            
//            AxisMarks(
//                values: [25, 75]
//            ) {
//                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2,4]))
//            }
//        }
//        .chartYScale(domain: [0, 100])
        .chartXScale(domain: [0, rpm.count], type: .linear)
        .chartXVisibleDomain(length: rpm.count)
        .chartScrollableAxes(.horizontal)
    }
}
