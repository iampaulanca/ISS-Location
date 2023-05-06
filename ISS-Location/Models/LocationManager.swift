//
//  LocationManager.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation
import MapKit

class LocationManager: NSObject {
    var locationManager: CLLocationManager?
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation, span: MapDetails.startingLocationSpan )
}

extension LocationManager: ObservableObject, CLLocationManagerDelegate {
    
    func checkIfLocationServiceIsEnabled() {
        Task { @MainActor in
            if await locationServicesEnabled() {
                locationManager = CLLocationManager()
                guard let locationManager = self.locationManager else { return }
                locationManager.delegate = self
                locationManager.activityType = .other
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
            } else {
                print("show alert and let them know to turn it on")
            }
            
        }
    }
    
    func locationServicesEnabled() async -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("show alert restricted / maybe parental control")
        case .denied:
            print("alert you have denied. go into settings and change application ")
        case .authorizedAlways, .authorizedWhenInUse:
            if let coordinate = locationManager.location?.coordinate {
                region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            } else {
                print("alert unable to get coordinate")
            }
        @unknown default:
            break
        }
    }
    
    // CLLocationManagerDelegate functions
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
