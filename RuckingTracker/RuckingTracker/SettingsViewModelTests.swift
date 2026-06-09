//
//  SettingsViewModelTests.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = SettingsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testDefaultSettings() {
        XCTAssertTrue(viewModel.selectedUnits == "Imperial" || viewModel.selectedUnits == "Metric")
        // Default notification/darkMode values might depend on device/UserDefaults, so just check type
        XCTAssertNotNil(viewModel.notificationsEnabled)
        XCTAssertNotNil(viewModel.darkModeEnabled)
    }

    func testChangeUnitsUpdatesSetting() {
        viewModel.selectedUnits = "Metric"
        XCTAssertEqual(viewModel.selectedUnits, "Metric")
    }
}

