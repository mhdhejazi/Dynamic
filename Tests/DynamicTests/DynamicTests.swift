import XCTest
@testable import Dynamic

final class DynamicTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Dynamic().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
