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
            Text("Location Info")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            Text("Current coordinates")
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Latitude: \(String(format: "%.4f", mainViewModel.fetchUsersCurrentLocation().coordinate.latitude))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.fetchUsersCurrentLocation().coordinate.longitude))")
                .padding(.bottom)
            Text("ISS coordinates")
                .bold()
            Text("Latitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.latitude ?? 0.0))")
            Text("Longitude: \(String(format: "%.4f", mainViewModel.currentISSLocation?.coordinate.longitude ?? 0.0))")
                .padding(.bottom)
            Text("Distance to ISS: ").bold() + Text("\(String(format: "%.4f", mainViewModel.currentDistanceToISS))KM")
            Spacer()
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
