//
//  MainViewModel.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation
import SwiftUI
import RealmSwift
import CoreLocation

enum MainViewModelErrors: Error {
    case networkError(String)
    case databaseError(String)
    case urlMissing
    case noISSLocation
}
extension MainViewModelErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .networkError(string):
            return "Failed network request reason: \(string)"
        case let .databaseError(string):
            return "Database error reason: \(string)"
        case .urlMissing:
            return "URL is missing or invalid"
        case .noISSLocation:
            return "No ISS Locations found"
        }
    }
}

@MainActor class MainViewModel: ObservableObject {
    // Observes changes to the location manager instance
    @ObservedObject var locationViewManager = LocationManager()
    
    // The current Realm instance being used by the view model
    @Published private var realm: Realm?
    
    // An array of all previously fetched ISS locations
    @Published var issPositionHistory = [ISSPositionResponse]()
    
    // An array of CLLocationCoordinate2D objects representing each ISS location
    @Published var locations = [CLLocationCoordinate2D]()
    
    // The most recent location of the ISS
    @Published var currentISSLocation: CLLocation?
    
    // The distance from the user's current location to the ISS
    @Published var currentDistanceToISS: Double = 0.0
    
    // An array of all astronauts currently on the ISS
    @Published var astronauts: [Astronaut] = []
    
    // Indicates whether an alert should be displayed
    @Published var alertShow = false
    
    // The message to be displayed in the alert
    @Published var alertMessage = ""
    
    // Indicates whether the view model is currently loading data
    @Published var isLoading = false
    
    init() {
        do {
            // Fetches the history of ISS locations and deletes any old objects
            try fetchHistory()
            try deleteOldObjects()
        } catch {
            // If an error occurs, display an alert with the error message
            alertShow = true
            alertMessage = "\(error)"
        }
    }
    
    // Fetches data from the local database
    func fetchHistory() throws {
        do {
            let realm = try Realm()
            self.realm = realm
            
            // Retrieves all saved ISS locations and sorts them by timestamp
            let locationsInMemory = realm.objects(ISSPositionResponse.self)
            let sortedLocations = locationsInMemory.sorted(byKeyPath: "timestamp", ascending: true)
            self.issPositionHistory = Array(sortedLocations)
            
            // Converts each ISS location to a CLLocationCoordinate2D object and appends it to the locations array
            for location in sortedLocations {
                if let lat = Double(location.position?.latitude ?? ""), let long = Double(location.position?.longitude ?? "") {
                    let coreLocation2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    locations.append(coreLocation2D)
                }
            }
        } catch {
            // If an error occurs, throw a MainViewModelErrors.databaseError with the error message
            throw MainViewModelErrors.databaseError(error.localizedDescription)
        }
        
    }
    
    // fetch current ISS position
    @discardableResult
    func fetchLocationOfISS() async throws -> ISSPositionResponse {
        do  {
            // create URL object with ISS position API endpoint
            guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { fatalError("need url") }
            // retrieve data from the URL using shared URLSession
            let (data, _) = try await URLSession.shared.data(from: url)
            // decode the JSON data into ISSPositionResponse object
            let issLocation = try JSONDecoder().decode(ISSPositionResponse.self, from: data)
            // if the position data exists, set the current ISS location to that position and update the map view accordingly
            if let issLocation = issLocation.position, let lat = Double(issLocation.latitude), let long = Double(issLocation.longitude) {
                currentISSLocation = CLLocation(latitude: lat, longitude: long)
                locationViewManager.region.center = CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            // save the ISS position data for later use
            try save(issLocation)
            // return the ISS position data
            return issLocation
        } catch {
            // throw a network error if the API request fails
            throw MainViewModelErrors.networkError("\(error.localizedDescription)")
        }
    }
    
    // fetch current astronauts in space
    @discardableResult
    func fetchAstronautsOnISS() async throws -> [Astronaut] {
        do  {
            // create URL object with astronauts API endpoint
            guard let url = URL(string: "http://api.open-notify.org/astros.json") else { throw MainViewModelErrors.urlMissing }
            // retrieve data from the URL using shared URLSession
            let (data, _) = try await URLSession.shared.data(from: url)
            // decode the JSON data into AstronautResponse object and get the list of astronauts
            let astronautsResponse = try JSONDecoder().decode(AstronautResponse.self, from: data)
            let astronauts = astronautsResponse.people
            // store the astronauts data in the view model
            self.astronauts = Array(astronauts)
            // return the list of astronauts
            return self.astronauts
        } catch {
            // throw a network error if the API request fails
            throw MainViewModelErrors.networkError("\(error.localizedDescription)")
        }
    }
    
    // fetch user's current location
    func fetchUsersCurrentLocation() -> CLLocation {
        // get the user's location from the location manager, or return the default starting location if the location is not available
        return locationViewManager.locationManager?.location ?? MapDetails.startingLocation
    }
    
    // calculate distance to ISS from user's current position
    // if the user's current position is not available, use Apple's Cupertino HQ as default
    func calculateDistanceToISS() async throws {
        // fetch the current ISS position
        try await fetchLocationOfISS()
        // if the current ISS position is available, calculate the distance to the user's current location
        guard let currentISSLocation = currentISSLocation else { throw MainViewModelErrors.noISSLocation }
        currentDistanceToISS = currentISSLocation.distance(from: fetchUsersCurrentLocation()) / 1000
    }
    
    // save new positions in database
    private func save(_ issLocation: ISSPositionResponse) throws {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(issLocation)
                // Append location to locations array if latitude and longitude are not nil
                if let lat = Double(issLocation.position?.latitude ?? ""), let long = Double(issLocation.position?.longitude ?? "") {
                    let coreLocation2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    locations.append(coreLocation2D)
                    issPositionHistory.append(issLocation)
                }
            }
        } catch {
            throw error
        }
    }
    
    // Delete cache that's 2 weeks old
    private func deleteOldObjects() throws {
        do {
            let realm = try Realm()
            let twoWeeksAgo = Int(Date().timeIntervalSince1970) - (14 * 24 * 60 * 60)
            // Query database for ISSPositionResponse objects that have a timestamp older than two weeks ago
            let objectsToDelete = realm.objects(ISSPositionResponse.self).filter("timestamp < %@", twoWeeksAgo)
            try realm.write {
                // Delete the objects that are older than two weeks ago
                realm.delete(objectsToDelete)
            }
        } catch {
            // Show an alert if there was an error deleting old objects
            print("error \(error)")
            self.alertShow = true
            self.alertMessage = "Unable to delete cache"
        }
    }
    
}
