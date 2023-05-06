//
//  MapView.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import SwiftUI
import MapKit

enum MapDetails {
    static let startingLocation = CLLocationCoordinate2D(latitude: 37.331516, longitude: -121.891054)
    static let startingLocationSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
}

struct MapView: View {
    @Binding var locationManager: LocationManager
    var body: some View {
        Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
            .edgesIgnoringSafeArea(.top)
            .tint(Color(.systemPink))
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(locationManager: .constant(.init()))
    }
}
