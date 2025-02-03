import XCTest
@testable import SwiftFSM

final class AnyActionSyntaxTests: AnyActionTestsBase {
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
        await assertAsync(AnyAction(pass) & passAsync, expected: "passpass")
        await assertAsync(AnyAction(pass) & passWithEventAsync, expected: "passevent")
    }

    func testCombinesAnyActionsArrays() async {
        let a = AnyAction(pass) & pass

        await assertAsync(a & passAsync, expected: "passpasspass")
        await assertAsync(a & passWithEventAsync, expected: "passpassevent")
    }

    func testOperatorChains() async {
        await assertAsync(AnyAction(pass) & pass & passAsync, expected: "passpasspass")
        await assertAsync(AnyAction(pass) & pass & passWithEventAsync, expected: "passpassevent")
    }

    func testCombinesRawActionsToFormAnyActions() async {
        await assertAsync(pass & passAsync, expected: "passpass")
        await assertAsync(pass & passWithEventAsync, expected: "passevent")

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
        await assertAsync(Array(passAsync), expected: "pass")
        await assertAsync(passAsync*, expected: "pass")
        await assertAsync(Array(passWithEventAsync), expected: "event")
        await assertAsync(passWithEventAsync*, expected: "event")
    }

    func passWithStringSync(_ s: String) { }
    func passWithStringAsync(_ s: String) async { }
    func passWithIntSync(_ i: Int) { }
    func passWithIntAsync(_ i: Int) { }
    
    func testHandlesMixedEventTypes() {
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
