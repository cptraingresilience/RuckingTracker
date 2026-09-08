import XCTest
import CoreLocation
@testable import RuckingTracker

// 1. Add @MainActor to the class declaration
@MainActor
class MapViewModelTests: XCTestCase {
    var sut: MapViewModel!

    override func setUp() {
        super.setUp()
        // Now this initializer call is safe because it's running on the MainActor
        sut = MapViewModel(locationManager: LocationManager(), activityStore: ActivityStore.shared)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // 2. These tests now implicitly run on the MainActor, fixing all isolation errors
    func testStartSessionInitializesMetrics() {
        sut.startSession()
        XCTAssertTrue(sut.isTracking)
        XCTAssertEqual(sut.distanceMeters, 0)
        XCTAssertEqual(sut.elapsedTime, 0)
        XCTAssertTrue(sut.route.isEmpty)
    }

    func testStopSessionEndsTracking() {
        sut.startSession()
        sut.stopSession()
        XCTAssertFalse(sut.isTracking)
    }
}
