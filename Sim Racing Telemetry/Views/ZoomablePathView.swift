//
//  ZoomablePathView.swift
//  Sim Racing Telemetry
//
//  Created by Niklas Lampen on 19.3.2024.
//

import Foundation

import SwiftUI

struct Coordinate {
    var x: Float
    var y: Float
}

struct PathSegment {
    var coordinates: [Coordinate]
    var color: Color
}

struct ImageSize {
    var width: Double = 0
    var height: Double = 0
}


struct ZoomablePathView: View {
    var imageSize: ImageSize
    var segments: [PathSegment]
    
    @State private var scale: CGFloat
    @State private var location: CGPoint
    
    @State private var dragStart: CGPoint? = nil
    
    init(imageSize: ImageSize, segments: [PathSegment]) {
        self.imageSize = imageSize
        self.imageSize.width += 50
        self.imageSize.height += 50
        
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
                    path.move(to: CGPoint(x: CGFloat(firstCoordinate.x + 25) * scale, y: CGFloat(firstCoordinate.y + 25) * scale))
                    
                    for coordinate in segment.coordinates.dropFirst() {
                        path.addLine(to: CGPoint(x: CGFloat(coordinate.x + 25) * scale, y: CGFloat(coordinate.y + 25) * scale))
                    }
                    
                    context.stroke(path, with: .color(segment.color), lineWidth: 2)
                }
            }
            .background(Color.yellow)
            .frame(width: CGFloat(imageSize.width) * scale, height: CGFloat(imageSize.height) * scale)
//            .clipped()
            .position(location)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if (self.dragStart == nil) {
                            self.dragStart = value.startLocation
                        }
                        
                        let newLocation: CGPoint = CGPoint(
                            x: self.location.x + value.location.x - (self.dragStart?.x ?? 0),
                            y: self.location.y + value.location.y - (self.dragStart?.y ?? 0)
                        )
                        self.location = newLocation
                        self.dragStart = value.location
                    }
                    .onEnded({ value in
                        self.dragStart = nil
                    })
            )
            .onAppear {
//                setupScrollGesture()
            }
        }
//        .gesture(MagnificationGesture().onChanged { value in
//            //debugPrint(value)
//            scale = scale + value
//        })
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
    let coordinates: [CoordinateDataPoint]
    
    var imageSize: ImageSize {
        var imageSize = ImageSize(width: 100, height: 100)
        
        let xs = coordinates.map { $0.coordinate.x }
        let ys = coordinates.map { $0.coordinate.z }
        
        if let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() {
            imageSize.width = Double(maxX - minX)
            imageSize.height = Double(maxY - minY)
        }
        
        return imageSize
    }
    
    private var adjustedCoordinates: [CoordinateDataPoint] {
        return adjustCoordinatesForCentering(coordinates: coordinates, imageSize: imageSize)
    }
    
    private var segments: [PathSegment] {
        var segments: [PathSegment] = []
        
        if adjustedCoordinates.count == 0 {
            return segments
        }
        
        var prevCoordinate: CoordinateDataPoint = adjustedCoordinates.first!
        
        adjustedCoordinates.forEach { coordinate in
            let segment = PathSegment(
                coordinates: [
                    Coordinate(
//                        x: Double(prevCoordinate.coordinate.x + Float(imageSize.width / 2)),
//                        y: Double(prevCoordinate.coordinate.z + Float(imageSize.height / 2))
                        x: prevCoordinate.coordinate.x, y: prevCoordinate.coordinate.z
                    ),
                    Coordinate(
//                        x: Double(coordinate.coordinate.x + Float(imageSize.width / 2)),
//                        y: Double(coordinate.coordinate.z + Float(imageSize.height / 2))
                        x: coordinate.coordinate.x, y: coordinate.coordinate.z
                    )
                ],
                color: getColor(state: coordinate.state)
            )
            
            segments.append(segment)
            
            prevCoordinate = coordinate
        }
        
        return segments
    }
    
    var body: some View {
        ZoomablePathView(imageSize: imageSize, segments: segments)
            .background(.white)
    }
    
    func getColor(state: ThrottleBrakeState) -> Color {
        if state == .onBrake {
            return .red
        }
        
        if state == .onThrottle {
            return .green
        }
        
        return .blue
    }
    
    func adjustCoordinatesForCentering(coordinates: [CoordinateDataPoint], imageSize: ImageSize) -> [CoordinateDataPoint] {
        guard !coordinates.isEmpty else { return [] }

        // Calculate bounds of the drawing
        let minX = coordinates.min(by: { $0.coordinate.x < $1.coordinate.x })?.coordinate.x ?? 0
        let maxX = coordinates.max(by: { $0.coordinate.x < $1.coordinate.x })?.coordinate.x ?? 0
        let minY = coordinates.min(by: { $0.coordinate.y < $1.coordinate.y })?.coordinate.y ?? 0
        let maxY = coordinates.max(by: { $0.coordinate.y < $1.coordinate.y })?.coordinate.y ?? 0

        // Calculate the center of the drawing
        let drawingCenterX = Double((minX + maxX) / 2)
        let drawingCenterY = Double((minY + maxY) / 2)

        // Calculate the center of the canvas
        let imageCenterX = imageSize.width / 2
        let imageCenterY = imageSize.height / 2

        // Calculate the offset needed to center the drawing on the canvas
        let offsetX = imageCenterX - drawingCenterX
        let offsetY = imageCenterY - drawingCenterY

        // Adjust coordinates with the calculated offset
        let adjustedCoordinates = coordinates.map {
            CoordinateDataPoint(
                coordinate: SIMD3<Float>(
                    x: $0.coordinate.x + Float(offsetX),
                    y: $0.coordinate.y + Float(offsetY),
                    z: $0.coordinate.z + Float(offsetY)
                ),
                state: $0.state
            ) }

        return adjustedCoordinates
    }
}

//#Preview {
//    ZoomableContentView(telemetry: DrivingSession.sampleSession1.laps[2].telemetry)
//}
