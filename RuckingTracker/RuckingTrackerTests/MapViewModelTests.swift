import XCTest
import CoreLocation
@testable import RuckingTracker

@MainActor
class MapViewModelTests: XCTestCase {
    var sut: MapViewModel!

    override func setUp() {
        super.setUp()
        sut = MapViewModel(locationManager: LocationManager(), activityStore: ActivityStore.shared)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testStartSessionInitializesMetrics() {
        sut.startSession()
        XCTAssertFalse(sut.isTracking)
        XCTAssertEqual(sut.distanceMeters, 0)
        XCTAssertEqual(sut.elapsedTime, 0)
        XCTAssertTrue(sut.route.isEmpty)
        XCTAssertEqual(sut.statusMessage, MapViewModel.foregroundOnlyTrackingMessage)
    }

    func testPermissionButtonTitleIsExplicitBeforeAuthorization() {
        XCTAssertEqual(sut.permissionButtonTitle, "Allow Location Access")
    }
}
