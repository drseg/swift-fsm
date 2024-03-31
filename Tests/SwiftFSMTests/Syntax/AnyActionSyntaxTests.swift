import XCTest
@testable import SwiftFSM

@MainActor
final class AnyActionSyntaxTests: AnyActionTestsBase {
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

    func testCanMakeAnyActionsArray() async {
        assertSync(AnyAction(pass) & pass, expected: "passpass")
        assertSync(AnyAction(pass) & passWithEvent, expected: "passevent")
        await assertAsync(AnyAction(pass) & passAsync, expected: "passpass")
        await assertAsync(AnyAction(pass) & passWithEventAsync, expected: "passevent")
    }

    func testCombinesAnyActionsArrays() async {
        let a = AnyAction(pass) & pass

        assertSync(a & pass, expected: "passpasspass")
        assertSync(a & passWithEvent, expected: "passpassevent")
        await assertAsync(a & passAsync, expected: "passpasspass")
        await assertAsync(a & passWithEventAsync, expected: "passpassevent")
    }

    func testOperatorChains() async {
        assertSync(AnyAction(pass) & pass & pass, expected: "passpasspass")
        assertSync(AnyAction(pass) & pass & passWithEvent, expected: "passpassevent")
        await assertAsync(AnyAction(pass) & pass & passAsync, expected: "passpasspass")
        await assertAsync(AnyAction(pass) & pass & passWithEventAsync, expected: "passpassevent")
    }

    func testCombinesRawActionsToFormAnyActions() async {
        assertSync(pass & pass, expected: "passpass")
        assertSync(pass & passWithEvent, expected: "passevent")
        await assertAsync(pass & passAsync, expected: "passpass")
        await assertAsync(pass & passWithEventAsync, expected: "passevent")

        assertSync(passWithEvent & pass, expected: "eventpass")
        assertSync(passWithEvent & passWithEvent, expected: "eventevent")
        await assertAsync(passWithEvent & passAsync, expected: "eventpass")
        await assertAsync(passWithEvent & passWithEventAsync, expected: "eventevent")

        await assertAsync(passAsync & pass, expected: "passpass")
        await assertAsync(passAsync & passWithEvent, expected: "passevent")
        await assertAsync(passAsync & passAsync, expected: "passpass")
        await assertAsync(passAsync & passWithEventAsync, expected: "passevent")

        await assertAsync(passWithEventAsync & pass, expected: "eventpass")
        await assertAsync(passWithEventAsync & passWithEvent, expected: "eventevent")
        await assertAsync(passWithEventAsync & passAsync, expected: "eventpass")
        await assertAsync(passWithEventAsync & passWithEventAsync, expected: "eventevent")
    }

    func testFormsArrayWithSingleAction() async {
        assertSync(Array(pass), expected: "pass")
        assertSync(pass*, expected: "pass")
        assertSync(Array(passWithEvent), expected: "event")
        assertSync(passWithEvent*, expected: "event")
        await assertAsync(Array(passAsync), expected: "pass")
        await assertAsync(passAsync*, expected: "pass")
        await assertAsync(Array(passWithEventAsync), expected: "event")
        await assertAsync(passWithEventAsync*, expected: "event")
    }

    func testHandlesMixedEventTypes() {
        /// No need to assert here, the check is that it compiles

        func passWithStringSync(_ s: String) { }
        func passWithStringAsync(_ s: String) async { }
        func passWithIntSync(_ i: Int) { }
        func passWithIntAsync(_ i: Int) { }

        let a = AnyAction(passWithStringSync) & passWithIntSync
        let b = AnyAction(passWithStringAsync) & passWithIntAsync
        let c = AnyAction(passWithStringSync) & passWithIntAsync
        let d = AnyAction(passWithStringAsync) & passWithIntSync

        let _ = a & passWithStringSync
        let _ = b & passWithStringAsync
        let _ = c & passWithStringSync
        let _ = d & passWithStringAsync

        let _ = passWithStringSync & passWithIntSync
        let _ = passWithStringAsync & passWithIntSync
        let _ = passWithStringAsync & passWithIntAsync
        let _ = passWithStringSync & passWithIntAsync
    }
}
