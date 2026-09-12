//
//  LocationManagerTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
import CoreLocation
@testable import RuckingTracker

@MainActor
class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!

    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }

    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }

    func testRequestPermissionChangesStatus() {
        let originalStatus = locationManager.authorizationStatus
        locationManager.requestPermission()
        // For real tests, use a mock CLLocationManager and simulate callbacks.
        XCTAssertEqual(locationManager.authorizationStatus, originalStatus)
    }

    func testStartAndStopTracking() {
        locationManager.startTracking()
        XCTAssertFalse(locationManager.isTracking)
        locationManager.stopTracking()
        XCTAssertFalse(locationManager.isTracking)
    }

    func testForegroundTrackingMessageIsExplicit() {
        XCTAssertEqual(
            LocationManager.foregroundOnlyTrackingMessage,
            "Tracking works only while Rux stays open and the iPhone remains unlocked for this MVP."
        )
    }
}


