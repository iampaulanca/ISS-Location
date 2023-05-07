//
//  AstronautResponse.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/6/23.
//

import Foundation
import RealmSwift

class AstronautResponse: Object, Codable {
    @objc dynamic var message: String = ""
    @objc dynamic var number: Int = 0
    var people = RealmSwift.List<Astronaut>()
    
    enum CodingKeys: String, CodingKey {
        case message
        case number
        case people
    }
}

class Astronaut: Object, Codable {
    @objc dynamic var craft: String = ""
    @objc dynamic var name: String = ""
    
    enum CodingKeys: String, CodingKey {
        case craft
        case name
    }
}
