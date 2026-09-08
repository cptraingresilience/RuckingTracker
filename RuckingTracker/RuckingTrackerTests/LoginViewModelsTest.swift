//
//  LoginViewModels.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import XCTest
@testable import RuckingTracker

class LoginViewModelTests: XCTestCase {
    var sut: LoginViewModel!

    override func setUp() {
        super.setUp()
        sut = LoginViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.username, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertFalse(sut.isLoading)
    }

    // Expand: Test login process using mock AuthService
}
