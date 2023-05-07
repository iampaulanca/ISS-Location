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

@MainActor class MainViewModel: ObservableObject {
    @ObservedObject var locationViewManager = LocationManager()
    @Published private var realm: Realm?
    @Published var locations = [CLLocationCoordinate2D]()
    @Published var currentISSLocation: CLLocation?
    @Published var currentDistanceToISS: Double = 0.0
    @Published var astronauts: [Astronaut] = []
    @Published var alertShow = false
    @Published var alertMessage = ""
    @Published var isLoading = false
    init() {
        if let realm = try? Realm() {
            self.realm = realm
            let locationsInMemory = realm.objects(ISSPositionResponse.self)
            let sortedLocations = locationsInMemory.sorted(byKeyPath: "timestamp", ascending: true)
            for location in sortedLocations {
                if let lat = Double(location.position?.latitude ?? ""), let long = Double(location.position?.longitude ?? "") {
                    let coreLocation2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    locations.append(coreLocation2D)
                }
            }
        } else {
            print("throw alert that realm isnt wortking")
        }
        
    }
    
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
            throw error
        }
    }

    @discardableResult
    func fetchAstronautsOnISS() async throws -> [Astronaut] {
        do  {
            guard let url = URL(string: "http://api.open-notify.org/astros.json") else { fatalError("need url") }
            let (data, _) = try await URLSession.shared.data(from: url)
            let astronautsResponse = try JSONDecoder().decode(AstronautResponse.self, from: data)
            let astronauts = astronautsResponse.people
            self.astronauts = Array(astronauts)
            return self.astronauts
        } catch {
            throw error
        }
    }
    
    func fetchUsersCurrentLocation() -> CLLocation {
        return locationViewManager.locationManager?.location ?? MapDetails.startingLocation
    }
    
    func calculateDistanceToISS() async throws {
        Task {
            do {
                try await fetchLocationOfISS()
                guard let currentISSLocation = currentISSLocation else { print("throw alert"); return }
                currentDistanceToISS = currentISSLocation.distance(from: fetchUsersCurrentLocation()) / 1000
            } catch {
                throw error
            }
        }
    }
    
    func save(_ issLocation: ISSPositionResponse) throws {
        do {
            try realm?.write {
                realm?.add(issLocation)
                if let lat = Double(issLocation.position?.latitude ?? ""), let long = Double(issLocation.position?.longitude ?? "") {
                    let coreLocation2D = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    locations.append(coreLocation2D)
                }
            }
        } catch {
            throw error
        }
    }
}
