//
//  AnalyticsServiceTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

class AnalyticsServiceTests: XCTestCase {

    func testLogEvent() {
        // This test just checks that logging does not crash (side effects not verified here)
        AnalyticsService.shared.logEvent("unit_test_event", parameters: ["key": "value"])
        XCTAssertTrue(true) // No-throw success is sufficient for this stub
    }

    func testTrackScreenView() {
        AnalyticsService.shared.trackScreenView(screenName: "TestView")
        XCTAssertTrue(true)
    }

    func testTrackActivityCompleted() {
        AnalyticsService.shared.trackActivityCompleted(activityID: "fakeID", distance: 5.2, duration: 2000)
        XCTAssertTrue(true)
    }
}




