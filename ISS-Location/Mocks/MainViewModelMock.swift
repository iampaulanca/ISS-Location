//
//  MainViewModelMock.swift
//  ISS-LocationUITests
//
//  Created by Paul Ancajima on 5/8/23.
//

import Foundation
import CoreLocation

@MainActor class MainViewModelMock: MainViewModel {
    var fetchHistoryError: MainViewModelErrors?
    var fetchPositionOfISSError: MainViewModelErrors?
    var fetchAstronautsOnISSError: MainViewModelErrors?
    var calculateDistanceToISSError: MainViewModelErrors?
    var fetchHistoryInvoked = 0
    var fetchHistorySuper = false
    /// TODO: add more error handling, add more stubs
    
    override func fetchHistory() throws {
        guard fetchHistoryError == nil else { throw MainViewModelErrors.databaseError("somethign went wrong") }
        if fetchHistorySuper {
            try? super.fetchHistory()
        }
        fetchHistoryInvoked += 1
    }
    
    @discardableResult
    override func fetchPositionOfISS() async throws -> ISSPositionResponse  {
        guard fetchPositionOfISSError == nil else { throw MainViewModelErrors.networkError("couldnt fetch location") }
        
        let dummyISSPositionResponse = try! JSONDecoder().decode(ISSPositionResponse.self, from: issPositionReponseJSONData)
        let lat = Double(dummyISSPositionResponse.position!.latitude)!
        let long = Double(dummyISSPositionResponse.position!.longitude)!
        let location = CLLocation(latitude: lat, longitude: long)
        self.currentISSLocation = location
        return dummyISSPositionResponse
    }
    
    @discardableResult
    override func fetchAstronautsOnISS() async throws -> [Astronaut] {
        guard fetchAstronautsOnISSError == nil else { throw MainViewModelErrors.networkError("couldnt fetch astronauts") }
        let dummyAstronautPositionResponse = try! JSONDecoder().decode(AstronautResponse.self, from: astronautReponseJSONData)
        self.astronauts = Array(dummyAstronautPositionResponse.people)
        return Array(dummyAstronautPositionResponse.people)
    }
    
    override func fetchUsersCurrentLocation() -> CLLocation {
        // use Apples HQ location
        return MapDetails.startingLocation
    }
    
    override func calculateDistanceToISS() async throws {
        guard calculateDistanceToISSError == nil else { throw MainViewModelErrors.networkError("couldnt calculate distance") }
        try await fetchPositionOfISS()
        guard let currentISSLocation = currentISSLocation else { throw MainViewModelErrors.noISSLocation }
        currentDistanceToISS = currentISSLocation.distance(from: fetchUsersCurrentLocation()) / 1000
    }
}

func dummyLocations() -> [CLLocationCoordinate2D] {
    let latitudes = [51.5074, 40.7128, 37.7749, 52.5200]
    let longitudes = [-0.1278, -74.0060, -122.4194, 13.4050]
    var locations = [CLLocationCoordinate2D]()

    for i in 0..<4 {
        let location = CLLocationCoordinate2D(latitude: latitudes[i], longitude: longitudes[i])
        locations.append(location)
    }
    return locations
}

let issPositionReponseJSONData = """
{
   "iss_position": {
      "longitude": "30.4980",
      "latitude": "50.4452"
   },
   "timestamp": 1658954161,
   "message": "success"
}
""".data(using: .utf8)!

let astronautReponseJSONData = """
{
  "message": "success",
  "number": 3,
  "people": [
    {
      "craft": "ISS",
      "name": "Mark Vande Hei"
    },
    {
      "craft": "ISS",
      "name": "Oleg Novitskiy"
    },
    {
      "craft": "ISS",
      "name": "Pyotr Dubrov"
    }
  ]
}
""".data(using: .utf8)!
