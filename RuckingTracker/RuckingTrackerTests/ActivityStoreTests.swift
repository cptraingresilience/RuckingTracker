//
//  ActivityStoreTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

// 1. Add @MainActor here so the test can safely access MainActor-isolated properties
@MainActor
class ActivityStoreTests: XCTestCase {
    var store: ActivityStore!

    override func setUp() {
        super.setUp()
        store = ActivityStore.shared
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // 2. Since the class is @MainActor, this method now runs on the Main Thread
    func testSaveAndLoadActivity() async {
        let testActivity = TrackedActivity(id: UUID(), distance: 2.5, duration: 3600, pace: 12, startedAt: Date())
        
        await store.save(testActivity)
        await store.loadActivities()
        
        // This will now work because 'store.activities' is safely accessed on the MainActor
        XCTAssertTrue(store.activities.contains(where: { $0.id == testActivity.id }))
    }
}


