//
//  ZoomablePathView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 19.3.2024.
//

import Foundation

import SwiftUI

struct Coordinate {
    var x: Double
    var y: Double
}

struct PathSegment {
    var coordinates: [Coordinate]
    var color: Color
}

struct ImageSize {
    var width: Int = 0
    var height: Int = 0
}


struct ZoomablePathView: View {
    var imageSize: ImageSize
    var segments: [PathSegment]
    
    @State private var scale: CGFloat
    @State private var location: CGPoint
    
    init(imageSize: ImageSize, segments: [PathSegment]) {
        self.imageSize = imageSize
        self.segments = segments
        self.scale = 1.0
        self.location = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
    }

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            Canvas { context, size in
                for segment in segments {
                    var path = Path()
                    
                    guard let firstCoordinate = segment.coordinates.first else { continue }
                    path.move(to: CGPoint(x: firstCoordinate.x * scale, y: firstCoordinate.y * scale))
                    
                    for coordinate in segment.coordinates.dropFirst() {
                        path.addLine(to: CGPoint(x: coordinate.x * scale, y: coordinate.y * scale))
                    }
                    
                    context.stroke(path, with: .color(segment.color), lineWidth: 2)
                }
            }
            .frame(width: CGFloat(imageSize.width) * scale, height: CGFloat(imageSize.height) * scale)
//            .clipped()
            .position(location)
            .gesture(
                DragGesture().onChanged { value in
                    debugPrint(value)
                    self.location = value.location
                }
            )
            .onAppear {
                setupScrollGesture()
            }
        }
//        .gesture(MagnificationGesture().onChanged { value in
//            //debugPrint(value)
//            scale = scale + value
//        })
        .background()
    }
    
    private func setupScrollGesture() {
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            let zoomFactor: CGFloat = 0.1
            let delta = event.scrollingDeltaY > 0 ? zoomFactor : -zoomFactor
            scale += delta
            scale = max(0.1, scale) // Prevents scale from becoming too small or negative
            
            return event
        }
    }
}


struct ZoomableContentView: View {
    let telemetry: [TelemetryData]
    
    var imageSize: ImageSize {
        var imageSize = ImageSize()
        
        var maxX: Float = 0
        var minX: Float = 0
        var maxY: Float = 0
        var minY: Float = 0
        
        telemetry.forEach { telemetry in
//            debugPrint(telemetry.position)
            minX = min(minX, telemetry.position.x)
            minY = min(minY, telemetry.position.z)
            
            maxX = max(maxX, telemetry.position.x)
            maxY = max(maxY, telemetry.position.z)
        }
        
        imageSize.width = Int(ceil(maxX * 2.0 + 20.0))
        imageSize.height = Int(ceil(maxY * 2 + 20))
        
        return imageSize
    }
    
    private var segments: [PathSegment] {
        var segments: [PathSegment] = []
        
        if telemetry.count == 0 {
            return segments
        }
        
        var prevTelemetry: TelemetryData = telemetry.first!
        
        telemetry.forEach { telemetry in
            let segment = PathSegment(
                coordinates: [
                    Coordinate(
                        x: Double(prevTelemetry.position.x + Float(imageSize.width / 2)),
                        y: Double(prevTelemetry.position.z + Float(imageSize.height / 2))
                    ),
                    Coordinate(
                        x: Double(telemetry.position.x + Float(imageSize.width / 2)),
                        y: Double(telemetry.position.z + Float(imageSize.height / 2))
                    )
                ],
                color: getColor(telemetry: telemetry)
            )
            
            segments.append(segment)
            
            prevTelemetry = telemetry
        }
        
        debugPrint()
        
        return segments
    }
    
    var body: some View {
        ZoomablePathView(imageSize: imageSize, segments: segments)
    }
    
    func getColor(telemetry: TelemetryData) -> Color {
        if telemetry.brake > 0 {
            return .red
        }
        
        if telemetry.throttle > 0 {
            return .green
        }
        
        return .blue
    }
}

#Preview {
    ZoomableContentView(telemetry: DrivingSession.sampleSession1.laps[2].telemetry)
}
