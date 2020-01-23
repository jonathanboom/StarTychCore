import XCTest
@testable import StarTychCore

final class StarTychCoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(StarTychCore().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
