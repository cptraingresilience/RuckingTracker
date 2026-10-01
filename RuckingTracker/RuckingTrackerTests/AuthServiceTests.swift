
//

import XCTest
@testable import RuckingTracker

class AuthServiceTests: XCTestCase {
    func testSocialSignInMessageExplainsDisabledState() {
        XCTAssertTrue(AuthService.shared.socialSignInUnavailableMessage.contains("temporarily unavailable"))
    }
}
