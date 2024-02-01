import XCTest
@testable import SwiftFSM

class ActionsBlockTests: BlockTestsBase {
    let eventOutput = ActionsBlockTests.defaultOutputWithEvent

    func abnComponents(of s: Sentence) -> (ActionsBlockNode, ActionsBlockNode) {
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
            _ b: Internal.MWTASentence,
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
        assertMWTA(Actions(pass) { mwtaBlock })
        assertMWTA(Actions([pass, pass]) { mwtaBlock },
                   expectedNodeOutput: "passpass") // internal only

        assertMWTA(actions(passAsync) { mwtaBlock })
        assertMWTA(Actions(passAsync) { mwtaBlock })
        assertMWTA(Actions([passAsync, passAsync]) { mwtaBlock },
                   expectedNodeOutput: "passpass") // internal only

        assertMWTA(Actions(passWithEvent) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(actions(passWithEvent) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions([passWithEvent, passWithEvent]) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput + eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent) // internal only

        assertMWTA(Actions(passWithEventAsync) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(actions(passWithEventAsync) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions([passWithEventAsync, passWithEventAsync]) { mwtaBlockWithEvent },
                   expectedNodeOutput: eventOutput + eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent) // internal only
    }

    func testMWABlocks() {
        func assertMWA(
            _ b: Internal.MWASentence,
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
        assertMWA(Actions(pass) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(pass) { Matching(P.a) | When(1, or: 2) }, 
                  expectedRestOutput: "", restFile: #file)
        assertMWA(Actions(pass) { Matching(P.a) | When(1, or: 2) }, 
                  expectedRestOutput: "", restFile: #file)

        assertMWA(actions(passAsync) { mwaBlock }, restLine: mwaLine)
        assertMWA(Actions(passAsync) { mwaBlock }, restLine: mwaLine)
        assertMWA(actions(passAsync) { Matching(P.a) | When(1, or: 2) }, 
                  expectedRestOutput: "", restFile: #file)
        assertMWA(Actions(passAsync) { Matching(P.a) | When(1, or: 2) }, 
                  expectedRestOutput: "", restFile: #file)

        assertMWA(Actions(passWithEvent) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(actions(passWithEvent) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEventAsync) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(actions(passWithEventAsync) { mwaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
    }

    func testMTABlocks() {
        func assertMTA(
            _ b: Internal.MTASentence,
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
        assertMTA(Actions(pass) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(pass) { Matching(P.a) | Then(1) }, 
                  expectedRestOutput: "", restFile: #file)
        assertMTA(Actions(pass) { Matching(P.a) | Then(1) }, 
                  expectedRestOutput: "", restFile: #file)

        assertMTA(actions(passAsync) { mtaBlock }, restLine: mtaLine)
        assertMTA(Actions(passAsync) { mtaBlock }, restLine: mtaLine)
        assertMTA(actions(passAsync) { Matching(P.a) | Then(1) }, 
                  expectedRestOutput: "", restFile: #file)
        assertMTA(Actions(passAsync) { Matching(P.a) | Then(1) }, 
                  expectedRestOutput: "", restFile: #file)

        assertMTA(Actions(passWithEvent) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(actions(passWithEvent) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(Actions(passWithEventAsync) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(actions(passWithEventAsync) { mtaBlockWithEvent },
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

    }

    func testCompoundMWTABlocks() {
        func assertMWTA(
            _ b: Internal.MWTASentence,
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
        assertMWTA(Actions(pass) { Actions(pass) { mwtaBlock } })

        assertMWTA(actions(passAsync) { actions(passAsync) { mwtaBlock } })
        assertMWTA(Actions(passAsync) { Actions(passAsync) { mwtaBlock } })

        assertMWTA(actions(pass) { actions(passAsync) { mwtaBlock } })
        assertMWTA(Actions(pass) { Actions(passAsync) { mwtaBlock } })

        assertMWTA(actions(passWithEvent) { actions(passWithEvent) { mwtaBlockWithEvent }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEvent) { Actions(passWithEvent) { mwtaBlockWithEvent }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)

        assertMWTA(actions(passWithEventAsync) { actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEventAsync) { Actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)

        assertMWTA(actions(passWithEvent) { actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
        assertMWTA(Actions(passWithEvent) { Actions(passWithEventAsync) {
            mwtaBlockWithEvent
        }},
                   expectedNodeOutput: eventOutput,
                   expectedRestOutput: eventOutput,
                   restLine: mwtaLineWithEvent)
    }

    func testCompoundMWABlocks() {
        func assertMWA(
            _ b: Internal.MWASentence,
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
        assertMWA(Actions(pass) { Actions(pass) { mwaBlock } })

        assertMWA(actions(passAsync) { actions(passAsync) { mwaBlock } })
        assertMWA(Actions(passAsync) { Actions(passAsync) { mwaBlock } })

        assertMWA(actions(pass) { actions(passAsync) { mwaBlock } })
        assertMWA(Actions(pass) { Actions(passAsync) { mwaBlock } })

        assertMWA(Actions(passWithEvent) { Actions(passWithEvent) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEvent) { Actions(passWithEvent) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)

        assertMWA(Actions(passWithEvent) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
        assertMWA(Actions(passWithEvent) { Actions(passWithEventAsync) { mwaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mwaLineWithEvent)
    }

    func testCompoundMTABlocks() {
        func assertMTA(
            _ b: Internal.MTASentence,
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
        assertMTA(Actions(pass) { Actions(pass) { mtaBlock } })

        assertMTA(actions(passAsync) { actions(passAsync) { mtaBlock } })
        assertMTA(Actions(passAsync) { Actions(passAsync) { mtaBlock } })

        assertMTA(actions(pass) { actions(passAsync) { mtaBlock } })
        assertMTA(Actions(pass) { Actions(passAsync) { mtaBlock } })

        assertMTA(actions(passWithEvent) { actions(passWithEvent) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEvent) { Actions(passWithEvent) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEventAsync) { Actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)

        assertMTA(actions(passWithEvent) { actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
        assertMTA(Actions(passWithEvent) { Actions(passWithEventAsync) { mtaBlockWithEvent }},
                  expectedNodeOutput: eventOutput,
                  expectedRestOutput: eventOutput,
                  restLine: mtaLineWithEvent)
    }
}
