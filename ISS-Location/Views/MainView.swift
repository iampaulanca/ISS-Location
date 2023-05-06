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
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            ISSInfoView(mainViewModel: mainViewModel)
                .onReceive(timer, perform: { _ in
                    Task {
                        print (try await mainViewModel.fetchLocationOfISS() )
                    }
                })
                .tabItem {
                    Image(systemName: "1.square.fill")
                    Text("First")
                }
            
            
            MapView(locationManager: $mainViewModel.locationViewManager)
                .tabItem {
                    Image(systemName: "2.square.fill")
                    Text("Second")
                }
        }
        .onAppear {
            mainViewModel.locationViewManager.checkIfLocationServiceIsEnabled()
        }

    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
