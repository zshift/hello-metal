import XCTest
@testable import hello_metal

final class hello_metalTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(hello_metal().text, "Hello, World!")
    }
}
