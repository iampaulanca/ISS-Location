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
        VStack {
            Text("Info View")
            List {
                ForEach(mainViewModel.locations, id: \.timestamp) { location in
                    Text("Lat: \(location.position?.latitude ?? "NA"), Long: \(location.position?.longitude ?? "NA")")
                }
                .onDelete(perform: delete)
            }
        }
    }
    func delete(at offsets: IndexSet) {
        do {
            if let realm = mainViewModel.realm {
                try realm.write {
                    realm.delete(mainViewModel.locations.filter({ offsets.contains(mainViewModel.locations.firstIndex(of: $0)!) }))
                    mainViewModel.locations.remove(atOffsets: offsets)
                }
            }
        } catch {
            print(error)
        }
    }
}

struct ISSInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ISSInfoView(mainViewModel: MainViewModel())
    }
}
