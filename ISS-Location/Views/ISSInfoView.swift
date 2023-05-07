//
//  ISSInfoView.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import SwiftUI

struct ISSInfoView: View {
    @ObservedObject var mainViewModel: MainViewModel
    var body: some View {
        VStack(alignment: .leading) {
            let delta = String(format: "%.4f", mainViewModel.currentDistanceToISS)
            Text("Current coordinates")
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Latitude: \(String(format: "%.4f", mainViewModel.fetchCurrentLocation().coordinate.latitude))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.fetchCurrentLocation().coordinate.longitude))")
                .padding(.bottom)
            
            Text("ISS coordinates")
                .bold()
            Text("Latitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.latitude ?? 0.0))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.longitude ?? 0.0))")
                .padding(.bottom)
            
            Text("Distance to ISS (KM): \(delta) KM")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}


struct ISSInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ISSInfoView(mainViewModel: testVM())
    }
}


@MainActor func testVM() -> MainViewModel {
    let viewModel = MainViewModel()
    let initialLongitude = "-122.45" // Starting longitude coordinate
    let initialLatitude = "37.75" // Starting latitude coordinate
    let increment = 0.01 // Increment by which to change the coordinates
    
    var currentLongitude = Double(initialLongitude)!
    var currentLatitude = Double(initialLatitude)!
    
    var locations = [ISSPositionResponse]()
    
    for i in 0..<10 {
        let location = ISSPositionResponse()
        location.timestamp = i * 5 // 5 seconds apart
        location.message = "Dummy location \(i)"
        
        let position = ISSPosition()
        position.longitude = String(currentLongitude)
        position.latitude = String(currentLatitude)
        location.position = position
        
        currentLongitude += increment
        currentLatitude += increment
        
        locations.append(location)
    }
    viewModel.locations = locations
    return viewModel
}
