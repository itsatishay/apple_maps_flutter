//
//  AppleMapController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 03.09.19.
//

import Foundation
import MapKit

public class AppleMapController: NSObject, FlutterPlatformView {
    var contentView: UIView
    var mapView: FlutterMapView
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var initialCameraPosition: [String: Any]
    var options: [String: Any]
    var currentlySelectedAnnotation: String?
    var snapShotOptions: MKMapSnapshotter.Options = MKMapSnapshotter.Options()
    var snapShot: MKMapSnapshotter?
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withargs args: Dictionary<String, Any> ,withId id: Int64) {
        self.options = args["options"] as! [String: Any]
        self.channel = FlutterMethodChannel(name: "apple_maps_plugin.luisthein.de/apple_maps_\(id)", binaryMessenger: registrar.messenger())
        
        self.mapView = FlutterMapView(channel: channel, options: options)
        self.registrar = registrar
        
        // To stop the odd movement of the Apple logo.
        self.contentView = UIScrollView()
        self.contentView.addSubview(mapView)
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.initialCameraPosition = args["initialCameraPosition"]! as! Dictionary<String, Any>
        
        super.init()
        
        self.mapView.delegate = self
        
        self.mapView.setCenterCoordinate(initialCameraPosition, animated: false)
        self.setMethodCallHandlers()
        
        if let annotationsToAdd: NSArray = args["annotationsToAdd"] as? NSArray {
            self.annotationsToAdd(annotations: annotationsToAdd)
        }
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polygonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polygonsToAdd)
        }
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
    }
    
    public func view() -> UIView {
        return contentView
    }
    
    private func setMethodCallHandlers() {
        channel.setMethodCallHandler({ [unowned self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if let args: Dictionary<String, Any> = call.arguments as? Dictionary<String,Any> {
                switch(call.method) {
                case "annotations#update":
                    self.annotationUpdate(args: args)
                    result(nil)
                    break
                case "annotations#showInfoWindow":
                    self.selectAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#hideInfoWindow":
                    self.hideAnnotation(with: args["annotationId"] as! String)
                    break
                case "annotations#isInfoWindowShown":
                    result(self.isAnnotationSelected(with: args["annotationId"] as! String))
                    break
                case "polylines#update":
                    self.polylineUpdate(args: args)
                    result(nil)
                    break
                case "polygons#update":
                    self.polygonUpdate(args: args)
                    result(nil)
                    break
                case "circles#update":
                    self.circleUpdate(args: args)
                    result(nil)
                    break
                case "map#update":
                    self.mapView.interpretOptions(options: args["options"] as! Dictionary<String, Any>)
                    break
                case "camera#animate":
                    self.animateCamera(args: args)
                    result(nil)
                    break
                case "camera#move":
                    self.moveCamera(args: args)
                    result(nil)
                    break
                case "camera#convert":
                    self.cameraConvert(args: args, result: result)
                    break
                case "map#takeSnapshot":
                    self.takeSnapshot(options: SnapshotOptions.init(options: args), onCompletion: { (snapshot: FlutterStandardTypedData?, error: Error?) -> Void in
                        result(snapshot ?? error)
                    })
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            } else {
                switch call.method {
                case "map#getVisibleRegion":
                    result(self.mapView.getVisibleRegion())
                    break
                case "map#isCompassEnabled":
                    if #available(iOS 9.0, *) {
                        result(self.mapView.showsCompass)
                    } else {
                        result(false)
                    }
                    break
                case "map#isPitchGesturesEnabled":
                    result(self.mapView.isPitchEnabled)
                    break
                case "map#isScrollGesturesEnabled":
                    result(self.mapView.isScrollEnabled)
                    break
                case "map#isZoomGesturesEnabled":
                    result(self.mapView.isZoomEnabled)
                    break
                case "map#isRotateGesturesEnabled":
                    result(self.mapView.isRotateEnabled)
                    break
                case "map#isMyLocationButtonEnabled":
                    result(self.mapView.isMyLocationButtonShowing ?? false)
                    break
                case "map#getMinMaxZoomLevels":
                    result([self.mapView.minZoomLevel, self.mapView.maxZoomLevel])
                    break
                case "camera#getZoomLevel":
                    result(self.mapView.calculatedZoomLevel)
                    break
                default:
                    result(FlutterMethodNotImplemented)
                    break
                }
            }
        })
    }
    
    private func annotationUpdate(args: Dictionary<String, Any>) -> Void {
        if let annotationsToAdd = args["annotationsToAdd"] as? NSArray {
            if annotationsToAdd.count > 0 {
                self.annotationsToAdd(annotations: annotationsToAdd)
            }
        }
        if let annotationsToChange = args["annotationsToChange"] as? NSArray {
            if annotationsToChange.count > 0 {
                self.annotationsToChange(annotations: annotationsToChange)
            }
        }
        if let annotationsToDelete = args["annotationIdsToRemove"] as? NSArray {
            if annotationsToDelete.count > 0 {
                self.annotationsIdsToRemove(annotationIds: annotationsToDelete)
            }
        }
    }
    
    private func polygonUpdate(args: Dictionary<String, Any>) -> Void {
        if let polyligonsToAdd: NSArray = args["polygonsToAdd"] as? NSArray {
            self.addPolygons(polygonData: polyligonsToAdd)
        }
        if let polygonsToChange: NSArray = args["polygonsToChange"] as? NSArray {
            self.changePolygons(polygonData: polygonsToChange)
        }
        if let polygonsToRemove: NSArray = args["polygonIdsToRemove"] as? NSArray {
            self.removePolygons(polygonIds: polygonsToRemove)
        }
    }
    
    private func polylineUpdate(args: Dictionary<String, Any>) -> Void {
        if let polylinesToAdd: NSArray = args["polylinesToAdd"] as? NSArray {
            self.addPolylines(polylineData: polylinesToAdd)
        }
        if let polylinesToChange: NSArray = args["polylinesToChange"] as? NSArray {
            self.changePolylines(polylineData: polylinesToChange)
        }
        if let polylinesToRemove: NSArray = args["polylineIdsToRemove"] as? NSArray {
            self.removePolylines(polylineIds: polylinesToRemove)
        }
    }
    
    private func circleUpdate(args: Dictionary<String, Any>) -> Void {
        if let circlesToAdd: NSArray = args["circlesToAdd"] as? NSArray {
            self.addCircles(circleData: circlesToAdd)
        }
        if let circlesToChange: NSArray = args["circlesToChange"] as? NSArray {
            self.changeCircles(circleData: circlesToChange)
        }
        if let circlesToRemove: NSArray = args["circleIdsToRemove"] as? NSArray {
            self.removeCircles(circleIds: circlesToRemove)
        }
    }
    
    private func moveCamera(args: Dictionary<String, Any>) -> Void {
        let positionData: Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: false)
                return
            }
            self.mapView.setBounds(positionData, animated: false)
        }
    }
    
    private func animateCamera(args: Dictionary<String, Any>) -> Void {
        let positionData: Dictionary<String, Any> = self.toPositionData(data: args["cameraUpdate"] as! Array<Any>, animated: true)
        if !positionData.isEmpty {
            guard let _ = positionData["moveToBounds"] else {
                self.mapView.setCenterCoordinate(positionData, animated: true)
                return
            }
            self.mapView.setBounds(positionData, animated: true)
        }
    }
    
    private func cameraConvert(args: Dictionary<String, Any>, result: FlutterResult) -> Void {
        guard let annotation = args["annotation"] as? Array<Double> else {
            result(nil)
            return
        }
        let point = self.mapView.convert(CLLocationCoordinate2D(latitude: annotation[0] , longitude: annotation[1]), toPointTo: self.view())
        result(["point": [point.x, point.y]])
    }
    
    private func toPositionData(data: Array<Any>, animated: Bool) -> Dictionary<String, Any> {
        var positionData: Dictionary<String, Any> = [:]
        if let update: String = data[0] as? String {
            switch(update) {
            case "newCameraPosition":
                if let _positionData : Dictionary<String, Any> = data[1] as? Dictionary<String, Any> {
                    positionData = _positionData
                }
            case "newLatLng":
                if let _positionData : Array<Any> = data[1] as? Array<Any> {
                    positionData = ["target": _positionData]
                }
            case "newLatLngZoom":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let zoom: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "zoom": zoom]
                }
            case "newLatLngBounds":
                if let _positionData: Array<Any> = data[1] as? Array<Any> {
                    let padding: Double = data[2] as? Double ?? 0
                    positionData = ["target": _positionData, "padding": padding, "moveToBounds": true]
                }
            case "zoomBy":
                if let zoomBy: Double = data[1] as? Double {
                    mapView.zoomBy(zoomBy: zoomBy, animated: animated)
                }
            case "zoomTo":
                if let zoomTo: Double = data[1] as? Double {
                    mapView.zoomTo(newZoomLevel: zoomTo, animated: animated)
                }
            case "zoomIn":
                mapView.zoomIn(animated: animated)
            case "zoomOut":
                mapView.zoomOut(animated: animated)
            default:
                positionData = [:]
            }
            return positionData
        }
        return [:]
    }
}


extension AppleMapController: MKMapViewDelegate {
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if ((self.mapView.mapContainerView) != nil) {
            let locationOnMap = self.mapView.region.center
            self.channel.invokeMethod("camera#onMove", arguments: ["position": ["heading": self.mapView.actualHeading, "target":  [locationOnMap.latitude, locationOnMap.longitude], "pitch": self.mapView.camera.pitch, "zoom": self.mapView.calculatedZoomLevel]])
        }
        self.channel.invokeMethod("camera#onIdle", arguments: "")
    }
    
    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.channel.invokeMethod("camera#onMoveStarted", arguments: "")
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is FlutterPolyline {
            return self.polylineRenderer(overlay: overlay)
        } else if overlay is FlutterPolygon {
            return self.polygonRenderer(overlay: overlay)
        } else if overlay is FlutterCircle {
            return self.circleRenderer(overlay: overlay)
        }
        return MKOverlayRenderer()
    }
}

extension AppleMapController {
    // Modified takeSnapshot method for AppleMapController.swift
// This implementation adds support for rendering annotations and overlays in snapshots

func takeSnapshot(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Parse arguments from Flutter
    let arguments = call.arguments as? [String: Any]
    let includeAnnotations = arguments?["includeAnnotations"] as? Bool ?? true
    let includeOverlays = arguments?["includeOverlays"] as? Bool ?? true
    
    // Configure snapshot options
    let options = MKMapSnapshotter.Options()
    options.region = mapView.region
    options.size = mapView.bounds.size
    options.scale = UIScreen.main.scale
    options.mapType = mapView.mapType
    options.showsBuildings = mapView.showsBuildings
    options.showsPointsOfInterest = mapView.showsPointsOfInterest
    
    // Create and start the snapshotter
    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.start { [weak self] snapshot, error in
        guard let self = self else { return }
        
        // Handle errors
        if let error = error {
            result(FlutterError(
                code: "SNAPSHOT_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
            return
        }
        
        guard let snapshot = snapshot else {
            result(FlutterError(
                code: "SNAPSHOT_ERROR",
                message: "Snapshot is nil",
                details: nil
            ))
            return
        }
        
        // Start drawing context
        let image = snapshot.image
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        
        // Draw the base map image
        image.draw(at: .zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            result(FlutterError(
                code: "SNAPSHOT_ERROR",
                message: "Failed to get graphics context",
                details: nil
            ))
            return
        }
        
        // Draw overlays (polylines, polygons, etc.) if requested
        if includeOverlays {
            self.drawOverlays(on: snapshot, in: context)
        }
        
        // Draw annotations if requested
        if includeAnnotations {
            self.drawAnnotations(on: snapshot, in: context)
        }
        
        // Get the final image and clean up
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Convert to PNG data and return
        if let data = finalImage?.pngData() {
            result(data)
        } else {
            result(FlutterError(
                code: "SNAPSHOT_ERROR",
                message: "Failed to convert image to PNG data",
                details: nil
            ))
        }
    }
}

// Helper method to draw overlays on the snapshot
private func drawOverlays(on snapshot: MKMapSnapshotter.Snapshot, in context: CGContext) {
    for overlay in mapView.overlays {
        // Handle polylines
        if let polyline = overlay as? MKPolyline {
            drawPolyline(polyline, on: snapshot, in: context)
        }
        // Handle polygons
        else if let polygon = overlay as? MKPolygon {
            drawPolygon(polygon, on: snapshot, in: context)
        }
        // Handle circles
        else if let circle = overlay as? MKCircle {
            drawCircle(circle, on: snapshot, in: context)
        }
    }
}

// Helper method to draw polylines
private func drawPolyline(_ polyline: MKPolyline, on snapshot: MKMapSnapshotter.Snapshot, in context: CGContext) {
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                          count: polyline.pointCount)
    polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
    
    let path = UIBezierPath()
    var isFirstPoint = true
    
    for coord in coords {
        // Check if coordinate is valid
        guard CLLocationCoordinate2DIsValid(coord) else { continue }
        
        let point = snapshot.point(for: coord)
        
        if isFirstPoint {
            path.move(to: point)
            isFirstPoint = false
        } else {
            path.addLine(to: point)
        }
    }
    
    // Get the renderer for this polyline to match the actual appearance
    if let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer {
        renderer.strokeColor?.setStroke()
        path.lineWidth = renderer.lineWidth
        path.lineJoinStyle = renderer.lineJoin
        path.lineCapStyle = renderer.lineCap
        
        // Apply dash pattern if exists
        if let pattern = renderer.lineDashPattern {
            let dashPattern = pattern.map { CGFloat($0.floatValue) }
            path.setLineDash(dashPattern, count: dashPattern.count, phase: renderer.lineDashPhase)
        }
    } else {
        // Default styling if no renderer found
        UIColor.systemBlue.setStroke()
        path.lineWidth = 3
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
    }
    
    path.stroke()
}

// Helper method to draw polygons
private func drawPolygon(_ polygon: MKPolygon, on snapshot: MKMapSnapshotter.Snapshot, in context: CGContext) {
    var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                          count: polygon.pointCount)
    polygon.getCoordinates(&coords, range: NSRange(location: 0, length: polygon.pointCount))
    
    let path = UIBezierPath()
    var isFirstPoint = true
    
    for coord in coords {
        guard CLLocationCoordinate2DIsValid(coord) else { continue }
        
        let point = snapshot.point(for: coord)
        
        if isFirstPoint {
            path.move(to: point)
            isFirstPoint = false
        } else {
            path.addLine(to: point)
        }
    }
    
    path.close()
    
    // Get the renderer for this polygon to match the actual appearance
    if let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer {
        // Fill
        if let fillColor = renderer.fillColor {
            fillColor.setFill()
            path.fill()
        }
        
        // Stroke
        if let strokeColor = renderer.strokeColor {
            strokeColor.setStroke()
            path.lineWidth = renderer.lineWidth
            path.stroke()
        }
    } else {
        // Default styling
        UIColor.systemBlue.withAlphaComponent(0.3).setFill()
        UIColor.systemBlue.setStroke()
        path.fill()
        path.lineWidth = 2
        path.stroke()
    }
}

// Helper method to draw circles
private func drawCircle(_ circle: MKCircle, on snapshot: MKMapSnapshotter.Snapshot, in context: CGContext) {
    let centerPoint = snapshot.point(for: circle.coordinate)
    
    // Calculate the radius in points
    let radiusInMeters = circle.radius
    let meterRadius = MKMapPointsPerMeterAtLatitude(circle.coordinate.latitude)
    let radiusInMapPoints = radiusInMeters * meterRadius
    
    // Get a point on the edge of the circle to calculate pixel radius
    let edgeCoordinate = MKMapPoint(centerPoint).coordinate(at: radiusInMeters, bearing: 0)
    let edgePoint = snapshot.point(for: edgeCoordinate)
    let radiusInPoints = hypot(edgePoint.x - centerPoint.x, edgePoint.y - centerPoint.y)
    
    let circlePath = UIBezierPath(arcCenter: centerPoint,
                                   radius: radiusInPoints,
                                   startAngle: 0,
                                   endAngle: .pi * 2,
                                   clockwise: true)
    
    // Get the renderer for this circle to match the actual appearance
    if let renderer = mapView.renderer(for: circle) as? MKCircleRenderer {
        // Fill
        if let fillColor = renderer.fillColor {
            fillColor.setFill()
            circlePath.fill()
        }
        
        // Stroke
        if let strokeColor = renderer.strokeColor {
            strokeColor.setStroke()
            circlePath.lineWidth = renderer.lineWidth
            circlePath.stroke()
        }
    } else {
        // Default styling
        UIColor.systemRed.withAlphaComponent(0.3).setFill()
        UIColor.systemRed.setStroke()
        circlePath.fill()
        circlePath.lineWidth = 2
        circlePath.stroke()
    }
}

// Helper method to draw annotations on the snapshot
private func drawAnnotations(on snapshot: MKMapSnapshotter.Snapshot, in context: CGContext) {
    // Sort annotations by latitude (north to south) so southern pins appear on top
    let sortedAnnotations = mapView.annotations.sorted { 
        $0.coordinate.latitude > $1.coordinate.latitude 
    }
    
    for annotation in sortedAnnotations {
        // Skip the user location annotation
        if annotation is MKUserLocation { continue }
        
        let point = snapshot.point(for: annotation.coordinate)
        
        // Get or create the annotation view
        let annotationView = getOrCreateAnnotationView(for: annotation)
        
        // Calculate the draw point (center bottom of the pin should be at the coordinate)
        var drawPoint = point
        drawPoint.x -= annotationView.bounds.width / 2
        
        // Adjust Y position based on the annotation view's centerOffset
        drawPoint.y -= annotationView.bounds.height
        drawPoint.y += annotationView.centerOffset.y
        
        // Save the current graphics state
        context.saveGState()
        
        // Draw the annotation view
        context.translateBy(x: drawPoint.x, y: drawPoint.y)
        
        // Render the view hierarchy
        annotationView.layer.render(in: context)
        
        // Restore the graphics state
        context.restoreGState()
        
        // Draw callout if needed (optional)
        if annotationView.isSelected {
            drawCallout(for: annotation, at: point, on: snapshot)
        }
    }
}

// Helper method to get or create annotation view
private func getOrCreateAnnotationView(for annotation: MKAnnotation) -> MKAnnotationView {
    // Try to get existing view from the map
    if let existingView = mapView.view(for: annotation) {
        return existingView
    }
    
    // Create appropriate annotation view based on type
    // Check if this is a marker annotation (you may need to adjust based on your annotation types)
    if let _ = annotation as? FlutterAnnotation {
        // Create marker annotation view
        let markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        
        // Apply custom styling if available
        // You'll need to extract these properties from your FlutterAnnotation class
        markerView.markerTintColor = .red // Default color
        markerView.glyphText = nil
        markerView.glyphImage = nil
        
        return markerView
    } else {
        // Default pin annotation view
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        pinView.pinTintColor = .red
        return pinView
    }
}

// Optional: Helper method to draw callouts
private func drawCallout(for annotation: MKAnnotation, at point: CGPoint, on snapshot: MKMapSnapshotter.Snapshot) {
    guard let title = annotation.title ?? nil, !title.isEmpty else { return }
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.black,
        .backgroundColor: UIColor.white
    ]
    
    let size = title.size(withAttributes: attributes)
    let calloutRect = CGRect(
        x: point.x - size.width / 2,
        y: point.y - 40 - size.height,
        width: size.width + 10,
        height: size.height + 5
    )
    
    // Draw background
    UIColor.white.setFill()
    UIBezierPath(roundedRect: calloutRect, cornerRadius: 5).fill()
    
    // Draw border
    UIColor.black.setStroke()
    let borderPath = UIBezierPath(roundedRect: calloutRect, cornerRadius: 5)
    borderPath.lineWidth = 0.5
    borderPath.stroke()
    
    // Draw text
    title.draw(at: CGPoint(x: calloutRect.minX + 5, y: calloutRect.minY + 2.5), 
               withAttributes: attributes)
}

}

// Extension to help with coordinate calculations
extension MKMapPoint {
    func coordinate(at distance: CLLocationDistance, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0 // meters
        let lat1 = self.coordinate.latitude * .pi / 180
        let lon1 = self.coordinate.longitude * .pi / 180
        let bearingRad = bearing * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
                       cos(lat1) * sin(distance / earthRadius) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
                                cos(distance / earthRadius) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, 
                                      longitude: lon2 * 180 / .pi)
    }
}
