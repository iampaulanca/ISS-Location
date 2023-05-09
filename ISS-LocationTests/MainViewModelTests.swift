//
//  MainViewModelTests.swift
//  ISS-LocationTests
//
//  Created by Paul Ancajima on 5/8/23.
//

import XCTest
@testable import ISS_Location

@MainActor final class MainViewModelTests: XCTestCase {

    var mockViewModel: MainViewModelMock!
    override func setUp() async throws {
        self.mockViewModel = MainViewModelMock()
    }
    func testInit() async throws {
        XCTAssert(mockViewModel.fetchHistoryInvoked == 1)
    }
    
    func testFetchHistory() throws {
        XCTAssertNotNil(mockViewModel.issPositionHistory)
    }
    
    func testFetchLocationOfISS() async throws {
        try await mockViewModel.fetchLocationOfISS()
        XCTAssertNotNil(mockViewModel.currentISSLocation)
    }
    
    func testFetchAstronautsOnISS() async throws {
        try await mockViewModel.fetchAstronautsOnISS()
        XCTAssertNotNil(mockViewModel.astronauts)
    }
    
    func testFetchUsersCurrentLocation() throws {
        XCTAssertEqual(mockViewModel.fetchUsersCurrentLocation(), MapDetails.startingLocation)
    }
    
    func testCalculateDistanceToISS() async throws {
        try await mockViewModel.calculateDistanceToISS()
        XCTAssertNotNil(mockViewModel.currentDistanceToISS)
    }

}
