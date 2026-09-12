
//

import XCTest
import UIKit
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

    func testSignInWithEmailReturnsBackendManagedAuthError() {
        let expect = expectation(description: "Backend-managed auth error handled")
        service.signInWithEmail(email: "fake@email.com", password: "badpassword") { result in
            switch result {
            case .success:
                XCTFail("AuthService should not handle email sign-in directly")
            case .failure(let error):
                guard case .unsupported(let message) = error else {
                    return XCTFail("Expected unsupported error, got \(error)")
                }
                XCTAssertTrue(message.contains("Rux backend API"))
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 2)
    }

    func testGoogleSignInReturnsDisabledError() {
        let expect = expectation(description: "Google sign-in disabled")
        service.signInWithGoogle(presenting: UIViewController()) { result in
            switch result {
            case .success:
                XCTFail("Google sign-in should be disabled until backend token exchange exists")
            case .failure(let error):
                guard case .unsupported(let message) = error else {
                    return XCTFail("Expected unsupported error, got \(error)")
                }
                XCTAssertTrue(message.contains("temporarily unavailable"))
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 2)
    }
}
