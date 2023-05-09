//
//  MainViewModelErrors.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/8/23.
//

import Foundation

enum MainViewModelErrors: Error {
    case networkError(String)
    case databaseError(String)
    case urlMissing
    case noISSLocation
}
extension MainViewModelErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .networkError(string):
            return "Failed network request reason: \(string)"
        case let .databaseError(string):
            return "Database error reason: \(string)"
        case .urlMissing:
            return "URL is missing or invalid"
        case .noISSLocation:
            return "No ISS Locations found"
        }
    }
}
