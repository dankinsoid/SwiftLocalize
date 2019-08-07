import XCTest
@testable import SwiftLocalize

final class SwiftLocalizeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftLocalize().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
