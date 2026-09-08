
//

import XCTest
@testable import RuckingTracker

class AuthServiceTests: XCTestCase {
    var service: AuthService!

    override func setUp() {
        super.setUp()
        service = AuthService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testSignInWithEmailHandlesError() {
        let expect = expectation(description: "Auth error handled")
        service.signInWithEmail(email: "fake@email.com", password: "badpassword") { result in
            switch result {
            case .success(_):
                XCTFail("Should not succeed with invalid credentials")
            case .failure(let error):
                XCTAssertNotNil(error)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 2)
    }

    // For thorough testing, inject a mock Firebase Auth for success and failure cases
}


