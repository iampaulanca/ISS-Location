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
    @ObservedObject var locationViewManager = LocationManager()
    @Published private var realm: Realm?
    @Published var locations = [CLLocationCoordinate2D]()
    @Published var issPositionHistory = [ISSPositionResponse]()
    @Published var currentISSLocation: CLLocation?
    @Published var currentDistanceToISS: Double = 0.0
    @Published var astronauts: [Astronaut] = []
    @Published var alertShow = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    init() {
        do {
            try fetchHistory()
            try deleteOldObjects()
        } catch {
            alertShow = true
            alertMessage = "\(error)"
        }
    }
    
    // fetch data from local database
    func fetchHistory() throws {
        do {
            let realm = try Realm()
            self.realm = realm
            let locationsInMemory = realm.objects(ISSPositionResponse.self)
            let sortedLocations = locationsInMemory.sorted(byKeyPath: "timestamp", ascending: true)
            self.issPositionHistory = Array(sortedLocations)
            for location in sortedLocations {
                if let lat = Double(location.position?.latitude ?? ""), let long = Double(location.position?.longitude ?? "") {
                    let coreLocation2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    locations.append(coreLocation2D)
                }
            }
        } catch {
            throw MainViewModelErrors.databaseError(error.localizedDescription)
        }
        
    }
    
    // fetch current ISS position
    @discardableResult
    func fetchLocationOfISS() async throws -> ISSPositionResponse {
        do  {
            guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { fatalError("need url") }
            let (data, _) = try await URLSession.shared.data(from: url)
            let issLocation = try JSONDecoder().decode(ISSPositionResponse.self, from: data)
            if let issLocation = issLocation.position, let lat = Double(issLocation.latitude), let long = Double(issLocation.longitude) {
                 currentISSLocation = CLLocation(latitude: lat, longitude: long)
                locationViewManager.region.center = CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            try save(issLocation)
            return issLocation
        } catch {
            throw MainViewModelErrors.networkError("\(error.localizedDescription)")
        }
    }

    // fetch current astronauts in space
    @discardableResult
    func fetchAstronautsOnISS() async throws -> [Astronaut] {
        do  {
            guard let url = URL(string: "http://api.open-notify.org/astros.json") else { throw MainViewModelErrors.urlMissing }
            let (data, _) = try await URLSession.shared.data(from: url)
            let astronautsResponse = try JSONDecoder().decode(AstronautResponse.self, from: data)
            let astronauts = astronautsResponse.people
            self.astronauts = Array(astronauts)
            return self.astronauts
        } catch {
            throw MainViewModelErrors.networkError("\(error.localizedDescription)")
        }
    }
    
    // fetch users current location
    func fetchUsersCurrentLocation() -> CLLocation {
        return locationViewManager.locationManager?.location ?? MapDetails.startingLocation
    }
    
    // calculate distance to ISS from users current position
    // if users current postion isn't available we will use Apple's cupertino HQ as default
    func calculateDistanceToISS() async throws {
        
            try await fetchLocationOfISS()
            guard let currentISSLocation = currentISSLocation else { throw MainViewModelErrors.noISSLocation }
            currentDistanceToISS = currentISSLocation.distance(from: fetchUsersCurrentLocation()) / 1000
        
    }
    
    // save new positions in database
    private func save(_ issLocation: ISSPositionResponse) throws {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(issLocation)
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
    
    // Delete cache thats 2 weeks old
    private func deleteOldObjects() throws {
        do {
            let realm = try Realm()
            let twoWeeksAgo = Int(Date().timeIntervalSince1970) - (14 * 24 * 60 * 60)
            let objectsToDelete = realm.objects(ISSPositionResponse.self).filter("timestamp < %@", twoWeeksAgo)
            try realm.write {
                realm.delete(objectsToDelete)
            }
        } catch {
            print("error \(error)")
            self.alertShow = true
            self.alertMessage = "Unable to delete cache"
        }
    }
}
