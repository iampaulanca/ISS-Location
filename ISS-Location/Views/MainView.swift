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
    @ObservedObject var mainViewModel = MainViewModel()
    @State var initialLoadCompleted = false
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView {
            ISSInfoView(mainViewModel: mainViewModel)
                .onReceive(timer, perform: { _ in
                    Task {
                        try await mainViewModel.calculateDistanceToISS()
                    }
                })
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("ISS Location")
                }
            
            AstronautListView(mainViewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Astronauts")
                }
            
            MapView(mainViewModel: mainViewModel)
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Map")
                }
        }
        .onAppear {
            mainViewModel.locationViewManager.checkIfLocationServiceIsEnabled()
            Task {
                try await mainViewModel.fetchAstronautsOnISS()
                try await mainViewModel.calculateDistanceToISS()
                initialLoadCompleted = true
            }
        }
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
