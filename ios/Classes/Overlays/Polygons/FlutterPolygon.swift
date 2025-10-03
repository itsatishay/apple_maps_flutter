//
//  FlutterPolygon.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 07.03.20.
//

import Foundation
import MapKit

class FlutterPolygon: MKPolygon {
    var strokeColor: UIColor?
    var fillColor: UIColor?
    var isConsumingTapEvents: Bool?
    var width: CGFloat?
    var isVisible: Bool?
    var id: String?
    var zIndex: Int? = -1
    var coordinates: [CLLocationCoordinate2D]?
    
    convenience init(fromDictionaray polygonData: Dictionary<String, Any>) {
        let points = polygonData["points"] as! NSArray
        var _points: [CLLocationCoordinate2D] = []
        for point in points {
           if let _point: NSArray = point as? NSArray {
               _points.append(CLLocationCoordinate2D.init(latitude: _point[0] as! CLLocationDegrees, longitude: _point[1] as! CLLocationDegrees))
           }
        }
        self.init(coordinates: _points, count: points.count)
        self.coordinates = _points
        self.strokeColor = JsonConversions.convertColor(data: polygonData["strokeColor"] as! NSNumber)
        self.fillColor = JsonConversions.convertColor(data: polygonData["fillColor"] as! NSNumber)
        self.isConsumingTapEvents = polygonData["consumeTapEvents"] as? Bool
        self.width = polygonData["strokeWidth"] as? CGFloat
        self.id = polygonData["polygonId"] as? String
        self.isVisible = polygonData["visible"] as? Bool
        self.zIndex = polygonData["zIndex"] as? Int
    }
    
    static func == (lhs: FlutterPolygon, rhs: FlutterPolygon) -> Bool {
        return lhs.strokeColor == rhs.strokeColor && lhs.fillColor == rhs.fillColor && lhs.isConsumingTapEvents == rhs.isConsumingTapEvents && lhs.width ==  rhs.width && lhs.isVisible == rhs.isVisible && lhs.zIndex == rhs.zIndex && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
    
    static func != (lhs: FlutterPolygon, rhs: FlutterPolygon) -> Bool {
        return !(lhs == rhs)
    }
}

extension FlutterPolygon: FlutterOverlay {
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer {
        let path = UIBezierPath()
        let shapeLayer = CAShapeLayer()

        if !(self.isVisible ?? true) {
            return shapeLayer
        }

        guard let coordinates = self.coordinates, !coordinates.isEmpty else {
            return shapeLayer
        }

        // Efficiently construct the path - move once, then add lines
        path.move(to: snapshot.point(for: coordinates[0]))
        for i in 1..<coordinates.count {
            path.addLine(to: snapshot.point(for: coordinates[i]))
        }

        path.addLine(to: snapshot.point(for: coordinates[0]))
        path.close()

        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = self.width ?? 0
        shapeLayer.strokeColor = self.strokeColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.fillColor = self.fillColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round

        return shapeLayer
    }
}


public extension MKPolygon {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)
        if polygonRenderer.path == nil {
          return false
        } else{
            return polygonRenderer.path.contains(polygonViewPoint)
        }
    }
}
