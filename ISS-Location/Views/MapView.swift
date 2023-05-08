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
    // Observable object to hold view model
    @ObservedObject var mainViewModel: MainViewModel
    
    // Index of known location for slider
    @State private var knownLocationIndex: Double = 0.0
    
    // State variable to hold ISS position
    @State private var knownLocation: ISSPositionResponse? = nil
    
    // Initialize the MapView with a MainViewModel and a known location index
    init(mainViewModel: MainViewModel, knownLocation: Double = 0.0) {
        self.mainViewModel = mainViewModel
        
        // Set the initial known location if the ISS position history is not empty
        if mainViewModel.issPositionHistory.count > 0 {
            _knownLocation = State(initialValue: mainViewModel.issPositionHistory[0])
        }
    }
    
    var body: some View {
        VStack {
            // Slider to select known location
            VStack {
                Text("Known Locations")
                Slider(value: $knownLocationIndex, in: 0...Double(mainViewModel.issPositionHistory.count-1), step: 1.0)
                    .padding(.horizontal)
                    .disabled(mainViewModel.issPositionHistory.isEmpty)
            }
            
            // MapUIViewRepresentable to display the map and annotations
            MapUIViewRepresentable(region: mainViewModel.locationViewManager.region, lineCoordinates: $mainViewModel.locations, knownLocation: $knownLocation)
                .ignoresSafeArea()
        }
        
        // Update known location when slider value changes
        .onChange(of: knownLocationIndex) { newValue in
            let index = Int(newValue)
            knownLocation = mainViewModel.issPositionHistory[index]
        }
    }
}

struct MapUIViewRepresentable: UIViewRepresentable {
    
    // Constants used for annotation titles
    enum Constants {
        static let iss = "ISS"
        static let issPositionHistory = "Past Position of the ISS"
    }
    
    // Map view properties
    let region: MKCoordinateRegion
    @Binding var lineCoordinates: [CLLocationCoordinate2D]
    @Binding var knownLocation: ISSPositionResponse?
    
    // Create the initial map view
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        
        let polyline = MKPolyline(coordinates: lineCoordinates, count: lineCoordinates.count)
        mapView.addOverlay(polyline)
        return mapView
    }
    
    // Update the map view with new data
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
            annotation.subtitle = Date().formatted(date: .abbreviated, time: .shortened)
            annotation.coordinate = CLLocationCoordinate2D(latitude: region.center.latitude, longitude: region.center.longitude)
            view.addAnnotation(annotation)
        }
        
        // Add a location history annotation
        if let position = knownLocation?.position, let lat = Double(position.latitude), let long = Double(position.longitude), let timestamp = knownLocation?.timestamp {
            let annotation = MKPointAnnotation()
            annotation.title = Constants.issPositionHistory
            annotation.subtitle =  Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(date: .abbreviated, time: .shortened)
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Update or add the annotation to the map view
            let existingAnnotation = view.annotations.first { $0.title == Constants.issPositionHistory } as? MKPointAnnotation
            if let existingAnnotation = existingAnnotation {
                existingAnnotation.subtitle = annotation.subtitle
                let tempCoordinate = existingAnnotation.coordinate
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
    
    // Create a coordinator to handle map view delegate methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // A coordinator to handle map view delegate methods
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapUIViewRepresentable
        
        init(_ parent: MapUIViewRepresentable) {
            self.parent = parent
        }
        
        // Customize the appearance of map overlays
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
