import XCTest
@testable import RuckingTracker

// Add @MainActor here so the entire test class runs on the Main Thread
@MainActor
class LogViewModelTests: XCTestCase {
    var viewModel: LogViewModel!

    override func setUp() {
        super.setUp()
        // Now safely accessing MainActor-isolated ActivityStore.shared and LogViewModel
        viewModel = LogViewModel(activityStore: ActivityStore.shared)
        viewModel.activities = [
            TrackedActivity(id: UUID(), distance: 5, duration: 3000, pace: 11.2, startedAt: Date()),
            TrackedActivity(id: UUID(), distance: 3.7, duration: 2500, pace: 12.0, startedAt: Date())
        ]
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // Because the class is @MainActor, these tests can now access
    // totalMiles, avgPaceString, etc., without errors.
    func testTotalMilesCalculation() {
        XCTAssertEqual(viewModel.totalMiles, 8.7, accuracy: 0.01)
    }

    func testAvgPaceStringFormat() {
        let avgPace = viewModel.avgPaceString
        XCTAssertTrue(avgPace.contains(":"))
    }

    func testBestRuckDistanceString() {
        XCTAssertEqual(viewModel.bestRuckDistanceString, "5.0")
    }
}
