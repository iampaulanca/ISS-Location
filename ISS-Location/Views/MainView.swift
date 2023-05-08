//
//  ContentView.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import SwiftUI
import CoreData
import CoreLocation
import MapKit

struct MainView: View {
    // Create an instance of MainViewModel, which will store all the data used in the app.
    @ObservedObject var mainViewModel = MainViewModel()

    // State variable to track if the initial load of data is completed.
    @State var initialLoadCompleted = false

    // Timer to update the ISS location every 5 seconds.
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        // Create a TabView with three tabs: ISSInfoView, AstronautListView, and MapView.
        TabView {
            // ISSInfoView tab shows the current location of the ISS.
            ISSInfoView(mainViewModel: mainViewModel)
                .onReceive(timer, perform: { _ in
                    // Every time the timer fires, calculate the distance from the user's location to the ISS.
                    Task {
                        try await mainViewModel.calculateDistanceToISS()
                    }
                })
                .tabItem {
                    // Set the tab icon and label.
                    Image(systemName: "info.circle")
                    Text("ISS Location")
                }

            // AstronautListView tab shows the list of astronauts currently on the ISS.
            AstronautListView(mainViewModel: mainViewModel)
                .tabItem {
                    // Set the tab icon and label.
                    Image(systemName: "person.crop.circle.fill")
                    Text("Astronauts")
                }

            // MapView tab shows the current location of the ISS on a map.
            MapView(mainViewModel: mainViewModel)
                .tabItem {
                    // Set the tab icon and label.
                    Image(systemName: "mappin.and.ellipse")
                    Text("Map")
                }
        }
        // When the TabView appears, check if location services are enabled and fetch the data for the app.
        .onAppear {
            mainViewModel.locationViewManager.checkIfLocationServiceIsEnabled()
            Task {
                try await mainViewModel.fetchAstronautsOnISS()
                try await mainViewModel.calculateDistanceToISS()
                initialLoadCompleted = true
            }
        }
        // Overlay a ProgressView while the initial data load is not completed.
        .overlay {
            ZStack {
                if !initialLoadCompleted {
                    ProgressView()
                        .scaleEffect(2.0)
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
