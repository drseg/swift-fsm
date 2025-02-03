import XCTest
@testable import SwiftFSM

class ActionsBlockTests: BlockTestsBase, @unchecked Sendable {
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
    ) async {
        await assertActionsBlock(b, expectedOutput: eo, sutLine: nl, xctLine: xl)
        await assertMWTAResult(b.rest, expectedOutput: er, sutLine: rl, xctLine: xl)
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
    ) async {
        await assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        await assertMWAResult(b.rest, expectedOutput: ero, sutFile: rf, sutLine: rl, xctLine: xl)
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
    ) async {
        await assertActionsBlock(b, expectedOutput: eno, sutLine: nl, xctLine: xl)
        await assertMTAResult(b.rest, expectedOutput: ero, sutFile: rf, sutLine: rl, xctLine: xl)
    }

    func assertActionsBlock(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        assertNeverEmptyNode(b, caller: "actions", sutLine: sl, xctLine: xl)
        await assertActions(b.actions, event: event, expectedOutput: eo, xctLine: xl)
    }
    
    func testMWTABlocks() async {
        func assertMWTA(
            _ b: Internal.MWTABlock,
            expectedNodeOutput eo: String = Self.defaultOutput,
            expectedRestOutput er: String = Self.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) async {
            await assertMWTANode(
                abn(b.node),
                expectedNodeOutput: eo,
                expectedRestOutput: er,
                nodeLine: sl,
                restLine: rl,
                xctLine: xl
            )
        }

        await assertMWTA(actions(pass) { mwtaBlock })
        await assertMWTA(actions(passAsync) { mwtaBlock })
        await assertMWTA(actions(passWithEvent) { mwtaBlock },
                         expectedNodeOutput: eventOutput)
        await assertMWTA(actions(passWithEventAsync) { mwtaBlock },
                         expectedNodeOutput: eventOutput)
        await assertMWTA(actions(pass & pass) { mwtaBlock},
                         expectedNodeOutput: Self.defaultOutput + Self.defaultOutput)
    }
    
    func testMWABlocks() async {
        func assertMWA(
            _ b: Internal.MWABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine sl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            await assertMWANode(
                abn(b.node),
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restFile: rf,
                restLine: rl,
                xctLine: xl
            )
        }
        
        await assertMWA(actions(pass) { mwaBlock }, restLine: mwaLine)
        await assertMWA(actions(pass) { matching(P.a) | when(1, or: 2) },
                        expectedRestOutput: "", restFile: #file)
        
        await assertMWA(actions(passAsync) { mwaBlock }, restLine: mwaLine)
        await assertMWA(actions(passAsync) { matching(P.a) | when(1, or: 2) },
                        expectedRestOutput: "", restFile: #file)
        
        await assertMWA(actions(passWithEvent) { mwaBlock },
                        expectedNodeOutput: eventOutput,
                        restLine: mwaLine)
        await assertMWA(actions(passWithEventAsync) { mwaBlock },
                        expectedNodeOutput: eventOutput,
                        restLine: mwaLine)
        
        await assertMWA(actions(pass & pass) { mwaBlock },
                        expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
                        restLine: mwaLine)
    }
    
    func testMTABlocks() async {
        func assertMTA(
            _ b: Internal.MTABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine nl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            await assertMTANode(
                abn(b.node),
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: nl,
                restFile: rf,
                restLine: rl,
                xctLine: xl
            )
        }
        
        await assertMTA(actions(pass) { mtaBlock }, restLine: mtaLine)
        await assertMTA(actions(pass) { matching(P.a) | then(1) },
                        expectedRestOutput: "",
                        restFile: #file)
        
        await assertMTA(actions(passAsync) { mtaBlock }, restLine: mtaLine)
        await assertMTA(actions(passAsync) { matching(P.a) | then(1) },
                        expectedRestOutput: "",
                        restFile: #file)
        
        await assertMTA(actions(passWithEvent) { mtaBlock },
                        expectedNodeOutput: eventOutput,
                        restLine: mtaLine)
        
        await assertMTA(actions(passWithEventAsync) { mtaBlock },
                        expectedNodeOutput: eventOutput,
                        restLine: mtaLine)
        
        await assertMTA(actions(pass & pass) { mtaBlock },
                        expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
                        restLine: mtaLine)
    }

    func testCompoundMWTABlocks() async {
        func assertMWTA(
            _ b: Internal.MWTABlock,
            expectedNodeOutput eo: String = BlockTestsBase.defaultOutput,
            expectedRestOutput er: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            xctLine xl: UInt = #line
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eo, sutLine: sl, xctLine: xl)
            await assertMWTANode(
                c.1,
                expectedNodeOutput: eo,
                expectedRestOutput: er,
                nodeLine: sl,
                restLine: rl,
                xctLine: xl
            )
        }
        
        await assertMWTA(actions(pass) { actions(pass) { mwtaBlock } })
        await assertMWTA(actions(passAsync) { actions(passAsync) { mwtaBlock } })
        await assertMWTA(actions(pass) { actions(passAsync) { mwtaBlock } })
        
        await assertMWTA(actions(passWithEvent) { actions(passWithEvent) { mwtaBlock }},
                         expectedNodeOutput: eventOutput)
        
        await assertMWTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mwtaBlock }},
                         expectedNodeOutput: eventOutput)
        
        await assertMWTA(actions(passWithEvent) { actions(passWithEventAsync) { mwtaBlock }},
                         expectedNodeOutput: eventOutput)
    }

    func testCompoundMWABlocks() async {
        func assertMWA(
            _ b: Internal.MWABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwaLine,
            xctLine xl: UInt = #line
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            await assertMWANode(
                c.1,
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restLine: rl,
                xctLine: xl
            )
        }
        
        await assertMWA(actions(pass) { actions(pass) { mwaBlock } })
        await assertMWA(actions(passAsync) { actions(passAsync) { mwaBlock } })
        await assertMWA(actions(pass) { actions(passAsync) { mwaBlock } })
        
        await assertMWA(actions(passWithEvent) { actions(passWithEvent) { mwaBlock }},
                        expectedNodeOutput: eventOutput)
        
        await assertMWA(actions(passWithEventAsync) { actions(passWithEventAsync) { mwaBlock }},
                        expectedNodeOutput: eventOutput)
        
        await assertMWA(actions(passWithEvent) { actions(passWithEventAsync) { mwaBlock }},
                        expectedNodeOutput: eventOutput)
    }
    
    func testCompoundMTABlocks() async {
        func assertMTA(
            _ b: Internal.MTABlock,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mtaLine,
            xctLine xl: UInt = #line
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, xctLine: xl)
            await assertMTANode(
                c.1,
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restLine: rl,
                xctLine: xl
            )
        }
        
        await assertMTA(actions(pass) { actions(pass) { mtaBlock } })
        await assertMTA(actions(passAsync) { actions(passAsync) { mtaBlock } })
        await assertMTA(actions(pass) { actions(passAsync) { mtaBlock } })
        await assertMTA(actions(passWithEvent) { actions(passWithEvent) { mtaBlock }},
                        expectedNodeOutput: eventOutput)
        await assertMTA(actions(passWithEventAsync) { actions(passWithEventAsync) { mtaBlock }},
                        expectedNodeOutput: eventOutput)
        await assertMTA(actions(passWithEvent) { actions(passWithEventAsync) { mtaBlock }},
                        expectedNodeOutput: eventOutput)
    }
}
