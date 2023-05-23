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
    static let maxLocationSpan = MKCoordinateSpan(latitudeDelta:130, longitudeDelta: 130)
}

struct MapView: View {
    // Observable object to hold view model
    @ObservedObject var mainViewModel: MainViewModel
    
    // Index of known location for slider
    @State private var knownPositionIndex: Double = 0.0
    
    // State variable to hold ISS position. Used as annotation in MapViewUIRepresentable
    @State private var knownPosition: ISSPositionResponse? = nil
    
    // Initialize the MapView with a MainViewModel and a known location index
    init(mainViewModel: MainViewModel, knownLocation: Double = 0.0) {
        self.mainViewModel = mainViewModel
        // Set the initial known location if the ISS position history is not empty
        if mainViewModel.issPositionHistory.count > 0 {
            _knownPosition = State(initialValue: mainViewModel.issPositionHistory[0])
        }
    }
    
    var body: some View {
        VStack {
            // Slider to select known location
            VStack(alignment: .leading) {
                Text("Previous Positions of ISS")
                    .bold()
                if mainViewModel.issPositionHistory.count > 1 {
                    Text("Time: \(mainViewModel.issPositionHistory[Int(knownPositionIndex)].timestamp.dateToString())")
                    Text("Latitude: \(mainViewModel.issPositionHistory[Int(knownPositionIndex)].position?.latitude ?? "NA")")
                    Text("Longitude: \(mainViewModel.issPositionHistory[Int(knownPositionIndex)].position?.latitude ?? "NA")")
                    Slider(value: $knownPositionIndex, in: 0...Double(mainViewModel.issPositionHistory.count-1), step: 1.0)
                        .padding(.horizontal)
                        .disabled(mainViewModel.issPositionHistory.isEmpty)
                } else {
                    Text("No recorded data")
                }

            }
            .padding(.horizontal)
            // MapUIViewRepresentable to display the map and annotations
            MapUIViewRepresentable(mainViewModel: mainViewModel, knownPosition: $knownPosition)
                .ignoresSafeArea()
        }
        // Update known location when slider value changes
        .onChange(of: knownPositionIndex) { newValue in
            let index = Int(newValue)
            knownPosition = mainViewModel.issPositionHistory[index]
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
    @ObservedObject var mainViewModel: MainViewModel
    @Binding var knownPosition: ISSPositionResponse?
    var region: MKCoordinateRegion?
    var knownPositions: [ISSPositionResponse] = []
    
    init(mainViewModel: MainViewModel, knownPosition: Binding<ISSPositionResponse?>) {
        self.mainViewModel = mainViewModel
        self.knownPositions = mainViewModel.issPositionHistory
        self._knownPosition = knownPosition
        self.region = mainViewModel.locationViewManager.region
    }
    
    // Create the initial map view
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = mainViewModel.locationViewManager.region
        mapView.showsUserLocation = true
        let processedPolyLines = processPolyLines(knownPositions: knownPositions)
        for processedPolyLine in processedPolyLines {
            mapView.addOverlay(processedPolyLine)
        }
        if let currentISSCoordinate = mainViewModel.currentISSLocation {
            let currentISSCoordinate = CLLocationCoordinate2D(latitude: currentISSCoordinate.coordinate.latitude, longitude: currentISSCoordinate.coordinate.longitude)
            let currentRegion = MKCoordinateRegion(center: currentISSCoordinate, span: MapDetails.maxLocationSpan)
            mapView.setRegion(currentRegion, animated: true)
        }
        return mapView
    }
    
    // Update the map view with new data
    func updateUIView(_ view: MKMapView, context: Context) {

        // Add or update the ISS annotation
        let existingAnnotation = view.annotations.first { $0.title == Constants.iss } as? MKPointAnnotation
        guard let region = region else { return }
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
        if let position = knownPosition?.position, let lat = Double(position.latitude), let long = Double(position.longitude), let timestamp = knownPosition?.timestamp {
            let annotation = MKPointAnnotation()
            annotation.title = Constants.issPositionHistory
            annotation.subtitle =  Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(date: .abbreviated, time: .shortened)
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Update or add the annotation to the map view
            let existingAnnotation = view.annotations.first { $0.title == Constants.issPositionHistory } as? MKPointAnnotation
            if let existingAnnotation = existingAnnotation {
                existingAnnotation.subtitle = annotation.subtitle
                if existingAnnotation.coordinate.latitude != annotation.coordinate.latitude && existingAnnotation.coordinate.longitude != annotation.coordinate.longitude {
                    existingAnnotation.coordinate = annotation.coordinate
                    let updateRegion = MKCoordinateRegion(center: existingAnnotation.coordinate, span: MapDetails.maxLocationSpan)
                    view.setRegion(updateRegion, animated: true)
                }
            } else {
                view.addAnnotation(annotation)
            }
        }
        
        let processedPolyLines = processPolyLines(knownPositions: knownPositions)
        view.removeOverlays(view.overlays)
        for processedPolyLine in processedPolyLines {
            view.addOverlay(processedPolyLine)
        }
    }
    
    /**
     Converts an `ISSPositionResponse` to a `CLLocationCoordinate2D` object.
     
     - Parameter issPositionReponse: An `ISSPositionResponse` object that contains position information.
     - Returns: A `CLLocationCoordinate2D` object if `position` property is not `nil`, `nil` otherwise.
     */
    private func makeCLLocation2DFrom(_ issPositionReponse: ISSPositionResponse) -> CLLocationCoordinate2D? {
        if let position = issPositionReponse.position {
            let lat = Double(position.latitude) ?? 0.0
            let long = Double(position.longitude) ?? 0.0
            return CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        return nil
    }
    
    /**
     Processes an array of `ISSPositionResponse` objects and returns an array of `MKPolyline` objects.
     
     - Parameter knownPositions: An array of `ISSPositionResponse` objects that contain position information.
     - Returns: An array of `MKPolyline` objects that connect the coordinates from `knownPositions` array.
     */
    private func processPolyLines(knownPositions: [ISSPositionResponse]) -> [MKPolyline] {
        var ret = [MKPolyline]()
        var tempCoordinates = [CLLocationCoordinate2D]()
        for i in 0..<knownPositions.count - 1 {
            if let position = knownPositions[i].position {
                let lat = Double(position.latitude) ?? 0.0
                let long = Double(position.longitude) ?? 0.0
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                if (knownPositions[i+1].timestamp - knownPositions[i].timestamp) > 30 {
                    // start a new tempCoordinate
                    ret.append(MKPolyline(coordinates: tempCoordinates, count: tempCoordinates.count))
                    tempCoordinates = []
                } else {
                    tempCoordinates.append(coordinate)
                }
            }
        }
        
        if !tempCoordinates.isEmpty {
            // add current coordinate to temp coordinates
            if let currentISSCoordinate = mainViewModel.currentISSLocation {
                let currentISSCoordinate = CLLocationCoordinate2D(latitude: currentISSCoordinate.coordinate.latitude, longitude: currentISSCoordinate.coordinate.longitude)
                tempCoordinates.append(currentISSCoordinate)
            }
            ret.append(MKPolyline(coordinates: tempCoordinates, count: tempCoordinates.count))
        }
        return ret
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
