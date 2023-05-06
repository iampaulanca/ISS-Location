//
//  ISSLocation.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation
import RealmSwift

class ISSLocation: Object, Codable {
    @objc dynamic var position: ISSPosition?
    @objc dynamic var timestamp: Int = 0
    @objc dynamic var message: String = ""

    enum CodingKeys: String, CodingKey {
        case position = "iss_position"
        case timestamp
        case message
    }

    override static func primaryKey() -> String? {
        return "timestamp"
    }
}

class ISSPosition: Object, Codable {
    @objc dynamic var longitude: String = ""
    @objc dynamic var latitude: String = ""
    
    enum CodingKeys: String, CodingKey {
        case longitude
        case latitude
    }
}
