//
//  LocationManager.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation
import MapKit

// LocationManager class which is responsible for managing location services
class LocationManager: NSObject, ObservableObject {
    var locationManager: CLLocationManager?
    @Published var region = MKCoordinateRegion(center: MapDetails.startingLocation2D, span: MapDetails.startingLocationSpan)
}

extension LocationManager: CLLocationManagerDelegate {
    
    // Function to check if location services are enabled and initialize the CLLocationManager instance if they are
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
    
    // Function to check if location services are enabled. Needed to suppress iOS 16 warning
    func locationServicesEnabled() async -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    // Private function to check the authorization status for location services and request permission if necessary
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
                region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            } else {
                print("alert unable to get coordinate")
            }
        @unknown default:
            break
        }
    }
    
    // CLLocationManagerDelegate function to handle changes in authorization status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
