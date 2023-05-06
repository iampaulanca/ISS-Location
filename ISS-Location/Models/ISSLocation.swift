//
//  ISSLocation.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/5/23.
//

import Foundation

struct ISSLocation: Codable {
    let position: ISSPosition
    let timestamp: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case position = "iss_position"
        case timestamp
        case message
    }
    
    struct ISSPosition: Codable {
        let longitude: String
        let latitude: String
    }
}
