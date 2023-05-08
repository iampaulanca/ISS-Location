//
//  MapView.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import SwiftUI
import MapKit

enum MapDetails {
    static let startingLocation2D = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let startingLocation = CLLocation(latitude: 37.331516, longitude: -121.891054)
    static let startingLocationSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    static let historyLocationSpan = MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
}

struct MapView: View {
    @ObservedObject var mainViewModel: MainViewModel
    @State private var knownLocationIndex: Double = 0.0
    @State private var knownLocation: ISSPositionResponse? = nil
    init(mainViewModel: MainViewModel, knownLocation: Double = 0.0) {
        self.mainViewModel = mainViewModel
        if mainViewModel.issPositionHistory.count > 0 {
            _knownLocation = State(initialValue: mainViewModel.issPositionHistory[0])
        }
    }

    var body: some View {
        VStack {
            VStack {
                Text("Known Locations")
                Slider(value: $knownLocationIndex, in: 0...Double(mainViewModel.issPositionHistory.count-1), step: 1.0)
                    .padding(.horizontal)
                    .disabled(mainViewModel.issPositionHistory.isEmpty)
            }
            MapUIViewRepresentable(region: mainViewModel.locationViewManager.region, lineCoordinates: $mainViewModel.locations, knownLocation: $knownLocation)
                .ignoresSafeArea()
        }
        .onChange(of: knownLocationIndex) { newValue in
            let index = Int(newValue)
            knownLocation = mainViewModel.issPositionHistory[index]
        }
    }
}

struct MapUIViewRepresentable: UIViewRepresentable {
    
    enum Constants {
        static let iss = "ISS"
        static let issPositionHistory = "ISS Position History"
    }
    
    let region: MKCoordinateRegion
    @Binding var lineCoordinates: [CLLocationCoordinate2D]
    @Binding var knownLocation: ISSPositionResponse?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        let polyline = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
        mapView.addOverlay(polyline)
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        let polyline = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
        view.removeOverlays(view.overlays)
        view.addOverlay(polyline)
        
        // Add or update the ISS annotation
        let existingAnnotation = view.annotations.first { $0.title == Constants.iss } as? MKPointAnnotation
        if let existingAnnotation = existingAnnotation {
            existingAnnotation.coordinate = CLLocationCoordinate2D(latitude: region.center.latitude, longitude: region.center.longitude)
        } else {
            let annotation = MKPointAnnotation()
            annotation.title = Constants.iss
            annotation.coordinate = CLLocationCoordinate2D(latitude: region.center.latitude, longitude: region.center.longitude)
            view.addAnnotation(annotation)
        }
        
        // Add knownLocation annotation
        if let position = knownLocation?.position, let lat = Double(position.latitude), let long = Double(position.longitude) {
            let annotation = MKPointAnnotation()
            annotation.title = Constants.issPositionHistory
            annotation.subtitle = knownLocation?.timestamp.dateToString()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let existingAnnotation = view.annotations.first { $0.title == Constants.issPositionHistory } as? MKPointAnnotation
            
            if let existingAnnotation = existingAnnotation {
                existingAnnotation.subtitle = annotation.subtitle
                var tempCoordinate = existingAnnotation.coordinate
                existingAnnotation.coordinate = annotation.coordinate
                let updateRegion = MKCoordinateRegion(center: existingAnnotation.coordinate, span: MapDetails.historyLocationSpan)
                if tempCoordinate.latitude != lat && tempCoordinate.longitude != long {
                    view.setRegion(updateRegion, animated: true)
                }
            } else {
                view.addAnnotation(annotation)
            }
            
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapUIViewRepresentable
        
        init(_ parent: MapUIViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routePolyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(mainViewModel: MainViewModel(), knownLocation: 0.0)
    }
}
