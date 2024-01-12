import XCTest
@testable import SwiftFSM

final class AnyActionTests: XCTestCase {
    func testCanCallActionWithNoArgs() {
        var output = ""
        let action = AnyAction { output = "pass" }
        action()

        XCTAssertEqual(output, "pass")
    }

    func testCanCallActionWithEventArg() {
        var output = ""
        let action = AnyAction { output = $0 }
        action("pass")

        XCTAssertEqual(output, "pass")
    }

    func testCallSafelyThrowsIfTypeError() {
        let action = AnyAction { let _: String = $0 }
        XCTAssertThrowsError(try action.callSafely())
    }

    func testCallSafelyDoesNotThrowIfNoError() {
        var output = ""
        let action = AnyAction { output = $0 }
        try? action.callSafely("pass")

        XCTAssertEqual(output, "pass")
    }
}
