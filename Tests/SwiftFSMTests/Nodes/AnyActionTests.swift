import Testing
@testable import SwiftFSM

class AnyActionTestsBase {
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
    @Test func canCallAsyncActionWithNoArgs() async {
        let action = AnyAction(passAsync)
        await action()

        #expect(output == "pass")
    }

    @Test func asyncActionWithNoArgsIgnoresEvent() async {
        let action = AnyAction(passAsync)
        await action("fail")

        #expect(output == "pass")
    }

    @Test func canCallSyncActionWithNoArgsWithAsync() async {
        let action = AnyAction(pass)
        await action()

        #expect(output == "pass")
    }

    @Test func canCallAsyncActionWithEventArg() async {
        let action = AnyAction(passWithEventAsync)
        await action("pass")

        #expect(output == "pass")
    }
}
