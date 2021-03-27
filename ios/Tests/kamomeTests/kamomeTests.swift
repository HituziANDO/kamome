import XCTest
@testable import kamome

final class kamomeTests: XCTestCase {
    func testScriptMessageHandlerName() {
        XCTAssertEqual(Client.scriptMessageHandlerName, "kamomeSend")
    }

    static var allTests = [
        ("testScriptMessageHandlerName", testScriptMessageHandlerName),
    ]
}
