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
        VStack(alignment: .leading, spacing: 5) {
            // Title
            Text("Location Info")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            // Current coordinates
            Text("Current coordinates")
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Latitude: \(String(format: "%.4f", mainViewModel.fetchUsersCurrentLocation().coordinate.latitude))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.fetchUsersCurrentLocation().coordinate.longitude))")
                .padding(.bottom)
            
            // ISS coordinates
            Text("ISS coordinates")
                .bold()
            Text("Latitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.latitude ?? 0.0))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.longitude ?? 0.0))")
                .padding(.bottom)
            
            // Distance to ISS
            Text("Distance to ISS: ").bold() + Text("\(String(format: "%.4f", mainViewModel.currentDistanceToISS))KM")
            
            // ISS Location History
            Text("ISS Location History")
                .bold()
                .padding(.top)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // List of ISS location history
            List {
                ForEach(mainViewModel.issPositionHistory, id: \.timestamp ) { location in
                    VStack(alignment: .leading) {
                        Text("Time: \(location.timestamp.dateToString())")
                        Text("Lat: \(location.position?.latitude ?? "NA")")
                        Text("Long: \(location.position?.longitude ?? "NA")")
                    }
                }
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

struct ISSInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ISSInfoView(mainViewModel: MainViewModel())
    }
}
