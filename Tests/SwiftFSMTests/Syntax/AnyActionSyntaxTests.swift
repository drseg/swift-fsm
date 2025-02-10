import XCTest
@testable import SwiftFSM

final class AnyActionSyntaxTests: AnyActionTestsBase {
    func assert(_ actions: [AnyAction], expected: String, line: UInt = #line) async {
        for a in actions {
            await a("event")
        }
        
        XCTAssertEqual(output, expected, line: line)
        output = ""
    }

    func testCanMakeAnyActionsArray() async {
        await assert(AnyAction(pass) & passAsync, expected: "passpass")
        await assert(AnyAction(pass) & passWithEventAsync, expected: "passevent")
    }

    func testCombinesAnyActionsArrays() async {
        let a = AnyAction(pass) & pass

        await assert(a & passAsync, expected: "passpasspass")
        await assert(a & passWithEventAsync, expected: "passpassevent")
    }

    func testOperatorChains() async {
        await assert(AnyAction(pass) & pass & passAsync, expected: "passpasspass")
        await assert(AnyAction(pass) & pass & passWithEventAsync, expected: "passpassevent")
    }

    func testCombinesRawActionsToFormAnyActions() async {
        await assert(pass & passAsync, expected: "passpass")
        await assert(pass & passWithEventAsync, expected: "passevent")

        await assert(passWithEvent & passAsync, expected: "eventpass")
        await assert(passWithEvent & passWithEventAsync, expected: "eventevent")

        await assert(passAsync & pass, expected: "passpass")
        await assert(passAsync & passWithEvent, expected: "passevent")
        await assert(passAsync & passAsync, expected: "passpass")
        await assert(passAsync & passWithEventAsync, expected: "passevent")

        await assert(passWithEventAsync & pass, expected: "eventpass")
        await assert(passWithEventAsync & passWithEvent, expected: "eventevent")
        await assert(passWithEventAsync & passAsync, expected: "eventpass")
        await assert(passWithEventAsync & passWithEventAsync, expected: "eventevent")
    }

    func testFormsArrayWithSingleAction() async {
        await assert(Array(passAsync), expected: "pass")
        await assert(passAsync*, expected: "pass")
        await assert(Array(passWithEventAsync), expected: "event")
        await assert(passWithEventAsync*, expected: "event")
    }

    func passWithStringSync(_ s: String) { }
    func passWithStringAsync(_ s: String) async { }
    func passWithIntSync(_ i: Int) { }
    func passWithIntAsync(_ i: Int) { }
    
    // Nothing to assert, must compile
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
