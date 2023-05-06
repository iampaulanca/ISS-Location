//
//  MainViewModel.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation
import SwiftUI
import RealmSwift

class MainViewModel: ObservableObject {
    @ObservedObject var locationViewManager = LocationManager()
    @Published var locations = [ISSLocation]()
    @Published var realm: Realm?
    
    init() {
        if let realm = try? Realm() {
            self.realm = realm
            let locationsInMemory = realm.objects(ISSLocation.self)
            let sortedLocations = locationsInMemory.sorted(byKeyPath: "timestamp", ascending: true)
            self.locations = Array(sortedLocations)
        } else {
            print("throw alert that realm isnt wortking")
        }
        
    }
    
    func fetchLocationOfISS() async throws -> ISSLocation {
        do  {
            guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { fatalError("need url") }
            let (data, _) = try await URLSession.shared.data(from: url)
            let issLocation = try JSONDecoder().decode(ISSLocation.self, from: data)
            try save(issLocation)
            return issLocation
        } catch {
            throw error
        }
    }
    
    func save(_ issLocation: ISSLocation) throws {
        do {
            try realm?.write {
                realm?.add(issLocation)
                locations.append(issLocation)
            }
        } catch {
            throw error
        }
    }
}
