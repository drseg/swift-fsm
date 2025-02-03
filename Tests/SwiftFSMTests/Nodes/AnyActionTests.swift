import XCTest
@testable import SwiftFSM

class AnyActionTestsBase: XCTestCase {
    var output = ""

    func pass() {
        output += "pass"
    }

    func passWithEvent(_ e: String) {
        output += e
    }

    func passAsync() async {
        pass()
    }

    func passWithEventAsync(_ e: String) async {
        passWithEvent(e)
    }
}

final class AnyActionTests: AnyActionTestsBase {
    func testCanCallAsyncActionWithNoArgs() async {
        let action = AnyAction(passAsync)
        await action()

        XCTAssertEqual(output, "pass")
    }

    func testAsyncActionWithNoArgsIgnoresEvent() async {
        let action = AnyAction(passAsync)
        await action("fail")

        XCTAssertEqual(output, "pass")
    }

    func testCanCallSyncActionWithNoArgsWithAsync() async {
        let action = AnyAction(pass)
        await action()

        XCTAssertEqual(output, "pass")
    }

    func testCanCallAsyncActionWithEventArg() async {
        let action = AnyAction(passWithEventAsync)
        await action("pass")

        XCTAssertEqual(output, "pass")
    }
}
