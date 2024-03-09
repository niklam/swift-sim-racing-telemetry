//
//  ContentView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 8.3.2024.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    let visibleTickCount = 600
    var throttleData: [Gt7Data] = []
    
    var displayData: [Gt7Data] {
        if throttleData.count > visibleTickCount {
            return throttleData.suffix(visibleTickCount)
        }
        
        var firstPackageId: Int {
            if throttleData.count == 0 {
                return 0
            }
            
            return throttleData[0].packageId
        }
        
        var array: [Gt7Data] = []
        let fillInItemsNeeded = visibleTickCount - throttleData.count
        
        if fillInItemsNeeded > 0 {
            for i in 1...fillInItemsNeeded {
                let data = Gt7Data()
                // 100 - 600 + 1
                data.packageId = firstPackageId - fillInItemsNeeded + i
                array.append(data)
            }
        }
        
        array.append(contentsOf: throttleData)
        
        return array
    }
    
    var latestData: Gt7Data {
        return displayData.last!
    }
    
    var minValue: Int {
        return Int(displayData[0].packageId)
    }
    
    var maxValue: Int {
        return Int(displayData[displayData.count-1].packageId)
    }

    var body: some View {
        VStack {
            HStack {
                Text("Time on track: ")
                TimeDisplay(timeInterval: latestData.timeOnTrack)
            }
            HStack {
                Text("Fastest lap: ")
                LapTimeDisplay(milliseconds: latestData.lapTimeFastestMs)
                    .foregroundColor(.purple)
                
                Text("Last lap: ")
                    .padding(.leading)
                LapTimeDisplay(milliseconds: latestData.lapTimeLastMs)
                    .foregroundColor(latestData.lapTimeLastMs <= latestData.lapTimeFastestMs ? .purple : .black)
            }
            VStack {
                Text(String(format: "%0.0f km/h", round(displayData.last?.carSpeed ?? 0)))
                    .bold()
                    .font(.largeTitle)
            }
            VStack {
                Text("Throttle and Brake").bold()
                Chart {
                    ForEach(self.displayData) {
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
        /*NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
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
            Text("Select an item")
        }*/
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

#Preview {
    ContentView(throttleData: Gt7Data.sampleCollection)
        .modelContainer(for: Item.self, inMemory: true)
}
