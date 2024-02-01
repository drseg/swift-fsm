import XCTest
@testable import SwiftFSM

class BlockTestsBase: SyntaxTestsBase {
    typealias MWTABuilder = Internal.MWTABuilder
    typealias MWABuilder = Internal.MWABuilder
    typealias MTABuilder = Internal.MTABuilder
    typealias Actions = Syntax.Actions<Event>

    let defaultFile = #file

    let mwtaLine = #line + 1; @MWTABuilder var mwtaBlock: [MWTA] {
        Matching(P.a) | When(1, or: 2) | Then(1) | pass
                        When(1, or: 2) | Then(1) | pass
        Matching(P.a) | When(1, or: 2) | Then(1) | passAsync
                        When(1, or: 2) | Then(1) | passAsync
    }

    let mwtaLineWithEvent = #line + 1; @MWTABuilder var mwtaBlockWithEvent: [MWTA] {
        Matching(P.a) | When(1, or: 2) | Then(1) | passWithEvent
                        When(1, or: 2) | Then(1) | passWithEvent
        Matching(P.a) | When(1, or: 2) | Then(1) | passWithEventAsync
                        When(1, or: 2) | Then(1) | passWithEventAsync
    }

    let mwaLine = #line + 1; @MWABuilder var mwaBlock: [MWA] {
        Matching(P.a) | When(1, or: 2) | pass
                        When(1, or: 2) | pass
        Matching(P.a) | When(1, or: 2) | passAsync
                        When(1, or: 2) | passAsync
    }

    let mwaLineWithEvent = #line + 1; @MWABuilder var mwaBlockWithEvent: [MWA] {
        Matching(P.a) | When(1, or: 2) | passWithEvent
                        When(1, or: 2) | passWithEvent
        Matching(P.a) | When(1, or: 2) | passWithEventAsync
                        When(1, or: 2) | passWithEventAsync
    }

    let mtaLineWithEvent = #line + 1; @MTABuilder var mtaBlockWithEvent: [MTA] {
        Matching(P.a) | Then(1) | passWithEvent
                        Then(1) | passWithEvent
        Matching(P.a) | Then(1) | passWithEventAsync
                        Then(1) | passWithEventAsync
    }

    let mtaLine = #line + 1; @MTABuilder var mtaBlock: [MTA] {
        Matching(P.a) | Then(1) | pass
                        Then(1) | pass
        Matching(P.a) | Then(1) | passAsync
                        Then(1) | passAsync
    }

    let maLineSync = #line + 1; var maBlockSync: MA {
        Matching(P.a) | pass
    }

    let maLineAsync = #line + 1; var maBlockAsync: MA {
        Matching(P.a) | passAsync
    }

    let maLineWithEventSync = #line + 1; var maBlockWithEventSync: MA {
        Matching(P.a) | passWithEvent
    }

    let maLineWithEventAsync = #line + 1; var maBlockWithEventAsync: MA {
        Matching(P.a) | passWithEventAsync
    }

    func outputEntry1() { output("entry1") }
    func outputEntry2() { output("entry2") }
    func outputExit1()  { output("exit1")  }
    func outputExit2()  { output("exit2")  }
    func output(_ s: String) { output += s }

    var entry1: [AnyAction] { Array(outputEntry1) }
    var entry2: [AnyAction] { Array(outputEntry2) }
    var exit1: [AnyAction]  { Array(outputExit1)  }
    var exit2: [AnyAction]  { Array(outputExit2)  }

    func assertMWTAResult(
        _ result: [AnyNode],
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let sf = sf == nil ? #file : sf!

        for i in stride(from: 0, to: result.count, by: 2) {
            assertMWTA(result[i],
                       event: event,
                       expectedOutput: eo,
                       sutFile: sf,
                       xctFile: xf,
                       sutLine: sl + i,
                       xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertWTA(result[i],
                       event: event,
                       expectedOutput: eo,
                       sutFile: sf,
                       xctFile: xf,
                       sutLine: sl + i,
                       xctLine: xl)
        }
    }

    func assertMWAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let sf = sf == nil ? #file : sf!

        for i in stride(from: 0, to: result.count, by: 2) {
            assertMWA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertWA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }
    }

    func assertMTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        let sf = sf == nil ? #file : sf!

        for i in stride(from: 0, to: result.count, by: 2) {
            assertMTA(result[i],
                      expectedOutput: eo,
                      sutFile: sf,
                      xctFile: xf,
                      sutLine: sl + i,
                      xctLine: xl)
        }

        for i in stride(from: 1, to: result.count, by: 2) {
            assertTA(result[i],
                     expectedOutput: eo,
                     sutFile: sf,
                     xctFile: xf,
                     sutLine: sl + i,
                     xctLine: xl)
        }
    }

    func assertMAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        xctFile xf: StaticString = #file,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        for i in 0..<result.count {
            assertMA(result[i],
                     expectedOutput: eo,
                     sutFile: defaultFile,
                     xctFile: xf,
                     sutLine: sl + i,
                     xctLine: xl)
        }
    }

    func assertGroupID(_ nodes: [any Node<DefaultIO>], line: UInt = #line) {
        let output = nodes.map { $0.finalised().output }
        XCTAssertEqual(3, output.count, line: line)

        let defineOutput = output.dropFirst().flattened
        defineOutput.forEach {
            XCTAssertEqual(defineOutput.first?.groupID, $0.groupID, line: line)
        }

        XCTAssertNotEqual(output.flattened.first?.groupID,
                          output.flattened.last?.groupID,
                          line: line)
    }
}
