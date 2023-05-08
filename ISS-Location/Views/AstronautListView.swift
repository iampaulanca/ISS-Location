//
//  AstronautListView.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/7/23.
//

import SwiftUI

struct AstronautListView: View {
    @ObservedObject var mainViewModel: MainViewModel
    
    var body: some View {
        VStack {
            // View title
            Text("Astronauts in space")
                .font(.title)
                .bold()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            // List of astronauts
            List {
                ForEach(mainViewModel.astronauts, id: \.name) { astronaut in
                    Text("\(astronaut.name) - \(astronaut.craft)")
                }
            }
            .listStyle(.plain)
        }
    }
}


struct AstronautListView_Previews: PreviewProvider {
    static var previews: some View {
        AstronautListView(mainViewModel: MainViewModel())
    }
}
