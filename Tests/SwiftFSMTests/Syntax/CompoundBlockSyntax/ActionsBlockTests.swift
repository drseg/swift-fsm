import XCTest
@testable import SwiftFSM

class ActionsBlockTests: BlockTestsBase {
    let eventOutput = ActionsBlockTests.defaultOutputWithEvent

    func abnComponents(of s: Internal.CompoundSyntax) -> (ActionsBlockNode, ActionsBlockNode) {
        let a1 = abn(s.node)
        let a2 = abn(a1.rest.first!)
        return (a1, a2)
    }

    func abn(_ n: any Node<DefaultIO>) -> ActionsBlockNode {
        n as! ActionsBlockNode
    }

    func assertMWTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eo: String,
        expectedRestOutput er: String = BlockTestsBase.defaultOutput,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eo, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, expectedOutput: er, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restFile rf: String? = nil,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, expectedOutput: ero, sutFile: rf, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restFile rf: String? = nil,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, expectedOutput: ero, sutFile: rf, sutLine: rl, xctLine: xl)
    }

    func assertActionsBlock(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "actions", sutLine: sl, xctLine: xl)
        assertActions(b.actions, event: event, expectedOutput: eo, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTA(
            _ b: Internal.MWTABlock,
            expectedNodeOutput eo: String = Self.defaultOutput,
            expectedRestOutput er: String = Self.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(abn(b.node),
                           expectedNodeOutput: eo,
                           expectedRestOutput: er,
                           nodeLine: sl,
                           restLine: rl,
                           xctLine: xl)
        }

        assertMWTA(actions(pass) { mwtaBlock })
        assertMWTA(actions(passAsync) { mwtaBlock })
        assertMWTA(actions(passWithEvent) { mwtaBlock },
                   expectedNodeOutput: eventOutput)
        assertMWTA(actions(passWithEventAsync) { mwtaBlock },
                   expectedNodeOutput: eventOutput)
        assertMWTA(actions(pass & pass) { mwtaBlock},
                   expectedNodeOutput: Self.defaultOutput + Self.defaultOutput)
    }

    func testMWABlocks() {
        func assertMWA(
            _ b: Internal.MWABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine sl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restFile: rf,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMWA(actions(pass) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(pass) { matching(P.a) | when(1, or: 2) },
                  expectedRestOutput: "", restFile: #file)

        assertMWA(actions(passAsync) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(passAsync) { matching(P.a) | when(1, or: 2) },
                  expectedRestOutput: "", restFile: #file)

        assertMWA(actions(passWithEvent) { mwaBlock }, 
                  expectedNodeOutput: eventOutput,
                  restLine: mwaLine)
        assertMWA(actions(passWithEventAsync) { mwaBlock }, 
                  expectedNodeOutput: eventOutput,
                  restLine: mwaLine)

        assertMWA(actions(pass & pass) { mwaBlock },
                  expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
                  restLine: mwaLine)
    }

    func testMTABlocks() {
        func assertMTA(
            _ b: Internal.MTABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine nl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(abn(b.node),
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: nl,
                          restFile: rf,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMTA(actions(pass) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(pass) { matching(P.a) | then(1) },
                  expectedRestOutput: "", 
                  restFile: #file)

        assertMTA(actions(passAsync) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(passAsync) { matching(P.a) | then(1) },
                  expectedRestOutput: "", 
                  restFile: #file)

        assertMTA(actions(passWithEvent) { mtaBlock },
                  expectedNodeOutput: eventOutput,
                  restLine: mtaLine)

        assertMTA(actions(passWithEventAsync) { mtaBlock },
                  expectedNodeOutput: eventOutput,
                  restLine: mtaLine)

        assertMTA(actions(pass & pass) { mtaBlock },
                  expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
                  restLine: mtaLine)
    }

    func testCompoundMWTABlocks() {
        func assertMWTA(
            _ b: Internal.MWTABlock,
            expectedNodeOutput eo: String = BlockTestsBase.defaultOutput,
            expectedRestOutput er: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eo, sutLine: sl, xctLine: xl)
            assertMWTANode(c.1,
                           expectedNodeOutput: eo,
                           expectedRestOutput: er,
                           nodeLine: sl,
                           restLine: rl,
                           xctLine: xl)
        }

        assertMWTA(actions(pass) { actions(pass) { mwtaBlock } })
        assertMWTA(actions(passAsync) { actions(passAsync) { mwtaBlock } })
        assertMWTA(actions(pass) { actions(passAsync) { mwtaBlock } })

        assertMWTA(actions(passWithEvent) { actions(passWithEvent) { mwtaBlock }},
                   expectedNodeOutput: eventOutput)

        assertMWTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mwtaBlock }},
                   expectedNodeOutput: eventOutput)

        assertMWTA(actions(passWithEvent) { actions(passWithEventAsync) { mwtaBlock }},
                   expectedNodeOutput: eventOutput)
    }

    func testCompoundMWABlocks() {
        func assertMWA(
            _ b: Internal.MWABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMWANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMWA(actions(pass) { actions(pass) { mwaBlock } })
        assertMWA(actions(passAsync) { actions(passAsync) { mwaBlock } })
        assertMWA(actions(pass) { actions(passAsync) { mwaBlock } })

        assertMWA(actions(passWithEvent) { actions(passWithEvent) { mwaBlock }},
                  expectedNodeOutput: eventOutput)

        assertMWA(actions(passWithEventAsync) { actions(passWithEventAsync) { mwaBlock }},
                  expectedNodeOutput: eventOutput)

        assertMWA(actions(passWithEvent) { actions(passWithEventAsync) { mwaBlock }},
                  expectedNodeOutput: eventOutput)
    }

    func testCompoundMTABlocks() {
        func assertMTA(
            _ b: Internal.MTABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mtaLine,
            xctLine xl: UInt = #line
        ) {
            let c = abnComponents(of: b)

            assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            assertMTANode(c.1,
                          expectedNodeOutput: eno,
                          expectedRestOutput: ero,
                          nodeLine: sl,
                          restLine: rl,
                          xctLine: xl)
        }

        assertMTA(actions(pass) { actions(pass) { mtaBlock } })
        assertMTA(actions(passAsync) { actions(passAsync) { mtaBlock } })
        assertMTA(actions(pass) { actions(passAsync) { mtaBlock } })
        assertMTA(actions(passWithEvent) { actions(passWithEvent) { mtaBlock }},
                  expectedNodeOutput: eventOutput)
        assertMTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mtaBlock }},
                  expectedNodeOutput: eventOutput)
        assertMTA(actions(passWithEvent) { actions(passWithEventAsync) { mtaBlock }},
                  expectedNodeOutput: eventOutput)
    }
}
