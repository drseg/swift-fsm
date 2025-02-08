import XCTest
@testable import SwiftFSM

class BlockTestsBase: SyntaxTestsBase {
    typealias MWTABuilder = Syntax.MWTABuilder
    typealias MWABuilder = Syntax.MWABuilder
    typealias MTABuilder = Syntax.MTABuilder
    typealias MABuilder = Syntax.MABuilder
    typealias Actions = Syntax.Actions<Event>

    let baseFile = #file

    let mwtaLine = #line + 1; @MWTABuilder var mwtaBlock: [Syntax.MatchingWhenThenActions] {
        matching(P.a) | when(1, or: 2) | then(1) | pass
                        when(1, or: 2) | then(1) | pass
    }

    let mwaLine = #line + 1; @MWABuilder var mwaBlock: [Syntax.MatchingWhenActions] {
        matching(P.a) | when(1, or: 2) | pass
                        when(1, or: 2) | pass
    }

    let mtaLine = #line + 1; @MTABuilder var mtaBlock: [Syntax.MatchingThenActions] {
        matching(P.a) | then(1) | pass
                        then(1) | pass
    }

    let maLine = #line + 1; var maBlock: Syntax.MatchingActions {
        matching(P.a) | pass
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
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let sf = sf == nil ? #file : sf!
        
        for i in stride(from: 0, to: result.count, by: 2) {
            await assertMWTA(
                result[i],
                event: event,
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
        
        for i in stride(from: 1, to: result.count, by: 2) {
            await assertWTA(
                result[i],
                event: event,
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
    }

    func assertMWAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let sf = sf == nil ? #file : sf!
        
        for i in stride(from: 0, to: result.count, by: 2) {
            await assertMWA(
                result[i],
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
        
        for i in stride(from: 1, to: result.count, by: 2) {
            await assertWA(
                result[i],
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
    }

    func assertMTAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutFile sf: String? = nil,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        let sf = sf == nil ? #file : sf!
        
        for i in stride(from: 0, to: result.count, by: 2) {
            await assertMTA(
                result[i],
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
        
        for i in stride(from: 1, to: result.count, by: 2) {
            await assertTA(
                result[i],
                expectedOutput: eo,
                sutFile: sf,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
    }
    
    func assertMAResult(
        _ result: [AnyNode],
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        xctFile xf: StaticString = #filePath,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        for i in 0..<result.count {
            await assertMA(
                result[i],
                expectedOutput: eo,
                sutFile: baseFile,
                xctFile: xf,
                sutLine: sl + i,
                xctLine: xl
            )
        }
    }

    func assertGroupID(_ nodes: [any Node<DefaultIO>], line: UInt = #line) {
        let output = nodes.map { $0.resolve().output }
        XCTAssertEqual(3, output.count, line: line)

        let defineOutput = output.dropFirst().flattened
        defineOutput.forEach {
            XCTAssertEqual(defineOutput.first?.overrideGroupID, $0.overrideGroupID, line: line)
        }

        XCTAssertNotEqual(output.flattened.first?.overrideGroupID,
                          output.flattened.last?.overrideGroupID,
                          line: line)
    }
}
