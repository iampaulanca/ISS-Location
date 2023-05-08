//
//  Int+dateToString.swift
//  ISS-Location
//
//  Created by Paul Ancajima on 5/7/23.
//

import Foundation

extension Int {
    func dateToString() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
