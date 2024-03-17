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
    @MainActor
    func testCanCallActionWithNoArgs() {
        let action = AnyAction(pass)
        try! action()

        XCTAssertEqual(output, "pass")
    }

    @MainActor
    func testActionWithNoArgsIgnoresEvent() {
        let action = AnyAction(pass)
        try! action("fail")

        XCTAssertEqual(output, "pass")
    }

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

    @MainActor
    func testCanCallActionWithEventArg() {
        let action = AnyAction(passWithEvent)
        try! action("pass")

        XCTAssertEqual(output, "pass")
    }

    @MainActor
    func testCannotCallActionWithEventArgWithoutEvent() {
        let action = AnyAction(passWithEvent)
        XCTAssertThrowsError(try action())
    }

    func testCanCallAsyncActionWithEventArg() async {
        let action = AnyAction(passWithEventAsync)
        await action("pass")

        XCTAssertEqual(output, "pass")
    }

    func testCanCallSyncActionWithEventArgWithAsync() async {
        let action = AnyAction(passWithEvent)
        await action("pass")

        XCTAssertEqual(output, "pass")
    }

    @MainActor
    func testCallingSyncFunctionWithAsyncBlockThrows() {
        let a1 = AnyAction(passAsync)
        let a2 = AnyAction(passWithEventAsync)

        XCTAssertThrowsError(try a1())
        XCTAssertThrowsError(try a2("pass"))
    }
}
