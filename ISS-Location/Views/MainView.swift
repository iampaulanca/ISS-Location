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

struct ISSInfoView: View {
    @ObservedObject var mainViewModel: MainViewModel
    var body: some View {
        VStack {
            Text("Info View")
            List(mainViewModel.locations, id: \.timestamp) { location in
                Text("Lat: \(location.position.latitude), Long: \(location.position.longitude)")
            }
        }
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

class MainViewModel: ObservableObject {
    @ObservedObject var locationViewManager = LocationManager()
    var locations = [ISSLocation]()
    
    func fetchLocationOfISS() async throws -> ISSLocation {
        do  {
            guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { fatalError("need url") }
            let (data, _) = try await URLSession.shared.data(from: url)
            let issLocation = try JSONDecoder().decode(ISSLocation.self, from: data)
            return issLocation
        } catch {
            throw error
        }
    }
}


/**
 
 @Environment(\.managedObjectContext) private var viewContext
 @FetchRequest(
     sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
     animation: .default)
 private var items: FetchedResults<Item>

 
 private func addItem() {
     withAnimation {
         let newItem = Item(context: viewContext)
         newItem.timestamp = Date()

         do {
             try viewContext.save()
         } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nsError = error as NSError
             fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
         }
     }
 }

 private func deleteItems(offsets: IndexSet) {
     withAnimation {
         offsets.map { items[$0] }.forEach(viewContext.delete)

         do {
             try viewContext.save()
         } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nsError = error as NSError
             fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
         }
     }
 }
 
 private let itemFormatter: DateFormatter = {
     let formatter = DateFormatter()
     formatter.dateStyle = .short
     formatter.timeStyle = .medium
     return formatter
 }()

 */
