import XCTest
@testable import SwiftFSM

@MainActor
final class AnyActionTests: XCTestCase {
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

    func testCanMakeManyActions() async {
        func assertSync(_ actions: [AnyAction], expected: String, line: UInt = #line) {
            for a in actions {
                try! a("event")
            }
            assert(actions, expected: expected, line: line)
        }

        func assertAsync(_ actions: [AnyAction], expected: String, line: UInt = #line) async {
            for a in actions {
                await a("event")
            }
            assert(actions, expected: expected, line: line)
        }

        func assert(_ actions: [AnyAction], expected: String, line: UInt = #line) {
            XCTAssertEqual(output, expected, line: line)
            output = ""
        }

        assertSync(AnyAction(pass) + pass, expected: "passpass")
        assertSync(AnyAction(pass) + passWithEvent, expected: "passevent")
        await assertAsync(AnyAction(pass) + passAsync, expected: "passpass")
        await assertAsync(AnyAction(pass) + passWithEventAsync, expected: "passevent")

        let a = AnyAction(pass) + pass

        assertSync(a + pass, expected: "passpasspass")
        assertSync(a + passWithEvent, expected: "passpassevent")
        await assertAsync(a + passAsync, expected: "passpasspass")
        await assertAsync(a + passWithEventAsync, expected: "passpassevent")

        assertSync(AnyAction(pass) + pass + pass, expected: "passpasspass")
        assertSync(AnyAction(pass) + pass + passWithEvent, expected: "passpassevent")
        await assertAsync(AnyAction(pass) + pass + passAsync, expected: "passpasspass")
        await assertAsync(AnyAction(pass) + pass + passWithEventAsync, expected: "passpassevent")
    }

    func testCanCallActionWithNoArgs() {
        let action = AnyAction(pass)
        try! action()

        XCTAssertEqual(output, "pass")
    }

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

    func testCanCallActionWithEventArg() {
        let action = AnyAction(passWithEvent)
        try! action("pass")

        XCTAssertEqual(output, "pass")
    }

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

    func testCallingSyncFunctionWithAsyncBlockThrows() {
        let a1 = AnyAction(passAsync)
        let a2 = AnyAction(passWithEventAsync)

        XCTAssertThrowsError(try a1())
        XCTAssertThrowsError(try a2("pass"))
    }
}
