//
//  ProfileViewModelTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

class ProfileViewModelTests: XCTestCase {
    var viewModel: ProfileViewModel!

    override func setUp() {
        super.setUp()
        viewModel = ProfileViewModel()
        let user = UserModel(id: UUID(), name: "Test User", profileImageName: "profile")
        let activities = [
            TrackedActivity(id: UUID(), distance: 10, duration: 3600, pace: 9.5, startedAt: Date()),
            TrackedActivity(id: UUID(), distance: 7.2, duration: 3300, pace: 10.2, startedAt: Date())
        ]
        viewModel.loadProfile(user: user, activities: activities)
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testStatsCalculation() {
        let milesStat = viewModel.stats.first(where: { $0.title == "Miles" })
        XCTAssertNotNil(milesStat)
        XCTAssertEqual(milesStat?.value, "17")
    }
}

