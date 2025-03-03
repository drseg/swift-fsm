import Testing
@testable import SwiftFSM

class ActionsBlockTests: BlockTestsBase {
    let eventOutput = ActionsBlockTests.defaultOutputWithEvent

    func abnComponents(
        of s: Syntax.CompoundSyntax
    ) -> (ActionsBlockNode, ActionsBlockNode) {
        let a1 = abn(s.node)
        let a2 = abn(a1.rest.first!)
        return (a1, a2)
    }

    func abn(_ n: any SyntaxNode<RawSyntaxDTO>) -> ActionsBlockNode {
        n as! ActionsBlockNode
    }

    func assertMWTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eo: String,
        expectedRestOutput er: String = BlockTestsBase.defaultOutput,
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertActionsBlock(b, expectedOutput: eo, sutLine: nl, location: location)
        await assertMWTAResult(b.rest, expectedOutput: er, sutLine: rl, location: location)
    }

    func assertMWANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restFile rf: String? = nil,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertActionsBlock(
            b,
            expectedOutput: eno,
            sutLine: nl,
            location: location
        )
        
        await assertMWAResult(
            b.rest,
            expectedOutput: ero,
            sutFile: rf,
            sutLine: rl,
            location: location
        )
    }

    func assertMTANode(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedNodeOutput eno: String,
        expectedRestOutput ero: String,
        nodeLine nl: Int,
        restFile rf: String? = nil,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertActionsBlock(
            b,
            expectedOutput: eno,
            sutLine: nl,
            location: location
        )
        
        await assertMTAResult(
            b.rest,
            expectedOutput: ero,
            sutFile: rf,
            sutLine: rl,
            location: location
        )
    }

    func assertActionsBlock(
        _ b: ActionsBlockNode,
        event: Event = BlockTestsBase.defaultEvent,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        assertNeverEmptyNode(b, caller: "actions", sutLine: sl, location: location)
        await assertActions(b.actions, event: event, expectedOutput: eo, location: location)
    }
    
    @Test func mwtaBlocks() async {
        func assertMWTA(
            _ b: Syntax.MWTA_Group,
            expectedNodeOutput eo: String = Self.defaultOutput,
            expectedRestOutput er: String = Self.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMWTANode(
                abn(b.node),
                expectedNodeOutput: eo,
                expectedRestOutput: er,
                nodeLine: sl,
                restLine: rl,
                location: location
            )
        }
        
        await assertMWTA(actions(pass) { mwtaBlock })
        await assertMWTA(actions(passAsync) { mwtaBlock })
        await assertMWTA(
            actions(passWithEvent) { mwtaBlock },
            expectedNodeOutput: eventOutput
        )
        
        await assertMWTA(
            actions(passWithEventAsync) { mwtaBlock },
            expectedNodeOutput: eventOutput
        )
        
        await assertMWTA(
            actions(pass & pass) { mwtaBlock},
            expectedNodeOutput: Self.defaultOutput + Self.defaultOutput
        )
    }
    
    @Test func mwaBlocks() async {
        func assertMWA(
            _ b: Syntax.MWA_Group,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine sl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMWANode(
                abn(b.node),
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restFile: rf,
                restLine: rl,
                location: location
            )
        }
        
        await assertMWA(actions(pass) { mwaBlock }, restLine: mwaLine)
        await assertMWA(
            actions(pass) { matching(P.a) | when(1, or: 2) },
            expectedRestOutput: "", restFile: #file
        )
        
        await assertMWA(actions(passAsync) { mwaBlock }, restLine: mwaLine)
        await assertMWA(
            actions(passAsync) { matching(P.a) | when(1, or: 2) },
            expectedRestOutput: "", restFile: #file
        )
        
        await assertMWA(
            actions(passWithEvent) { mwaBlock },
            expectedNodeOutput: eventOutput,
            restLine: mwaLine
        )
        
        await assertMWA(
            actions(passWithEventAsync) { mwaBlock },
            expectedNodeOutput: eventOutput,
            restLine: mwaLine
        )
        
        await assertMWA(
            actions(pass & pass) { mwaBlock },
            expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
            restLine: mwaLine
        )
    }
    
    @Test func mtaBlocks() async {
        func assertMTA(
            _ b: Syntax.MTA_Group,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            nodeLine nl: Int = #line,
            restFile rf: String? = nil,
            restLine rl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMTANode(
                abn(b.node),
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: nl,
                restFile: rf,
                restLine: rl,
                location: location
            )
        }
        
        await assertMTA(actions(pass) { mtaBlock }, restLine: mtaLine)
        await assertMTA(
            actions(pass) { matching(P.a) | then(1) },
            expectedRestOutput: "",
            restFile: #file
        )
        
        await assertMTA(actions(passAsync) { mtaBlock }, restLine: mtaLine)
        await assertMTA(
            actions(passAsync) { matching(P.a) | then(1) },
            expectedRestOutput: "",
            restFile: #file
        )
        
        await assertMTA(
            actions(passWithEvent) { mtaBlock },
            expectedNodeOutput: eventOutput,
            restLine: mtaLine
        )
        
        await assertMTA(
            actions(passWithEventAsync) { mtaBlock },
            expectedNodeOutput: eventOutput,
            restLine: mtaLine
        )
        
        await assertMTA(
            actions(pass & pass) { mtaBlock },
            expectedNodeOutput: Self.defaultOutput + Self.defaultOutput,
            restLine: mtaLine
        )
    }
    
    @Test func compoundMWTABlocks() async {
        func assertMWTA(
            _ b: Syntax.MWTA_Group,
            expectedNodeOutput eo: String = BlockTestsBase.defaultOutput,
            expectedRestOutput er: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwtaLine,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eo, sutLine: sl, location: location)
            await assertMWTANode(
                c.1,
                expectedNodeOutput: eo,
                expectedRestOutput: er,
                nodeLine: sl,
                restLine: rl,
                location: location
            )
        }
        
        await assertMWTA(actions(pass) { actions(pass) { mwtaBlock } })
        await assertMWTA(actions(passAsync) { actions(passAsync) { mwtaBlock } })
        await assertMWTA(actions(pass) { actions(passAsync) { mwtaBlock } })
        
        await assertMWTA(
            actions(passWithEvent) { actions(passWithEvent) { mwtaBlock }},
            expectedNodeOutput: eventOutput
        )
        
        await assertMWTA(
            actions(passWithEventAsync) { actions(passWithEventAsync) { mwtaBlock }},
            expectedNodeOutput: eventOutput
        )
        
        await assertMWTA(
            actions(passWithEvent) { actions(passWithEventAsync) { mwtaBlock }},
            expectedNodeOutput: eventOutput
        )
    }

    @Test func compoundMWABlocks() async {
        func assertMWA(
            _ b: Syntax.MWA_Group,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mwaLine,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, location: location)
            await assertMWANode(
                c.1,
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restLine: rl,
                location: location
            )
        }
        
        await assertMWA(actions(pass) { actions(pass) { mwaBlock } })
        await assertMWA(actions(passAsync) { actions(passAsync) { mwaBlock } })
        await assertMWA(actions(pass) { actions(passAsync) { mwaBlock } })
        
        await assertMWA(
            actions(passWithEvent) { actions(passWithEvent) { mwaBlock }},
            expectedNodeOutput: eventOutput
        )
        
        await assertMWA(
            actions(passWithEventAsync) { actions(passWithEventAsync) { mwaBlock }},
            expectedNodeOutput: eventOutput
        )
        
        await assertMWA(
            actions(passWithEvent) { actions(passWithEventAsync) { mwaBlock }},
            expectedNodeOutput: eventOutput
        )
    }
    
    @Test func compoundMTABlocks() async {
        func assertMTA(
            _ b: Syntax.MTA_Group,
            expectedNodeOutput eno: String = BlockTestsBase.defaultOutput,
            expectedRestOutput ero: String = BlockTestsBase.defaultOutput,
            sutLine sl: Int = #line,
            restLine rl: Int = mtaLine,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = abnComponents(of: b)
            
            await assertActionsBlock(c.0, expectedOutput: eno, sutLine: sl, location: location)
            await assertMTANode(
                c.1,
                expectedNodeOutput: eno,
                expectedRestOutput: ero,
                nodeLine: sl,
                restLine: rl,
                location: location
            )
        }
        
        await assertMTA(actions(pass) { actions(pass) { mtaBlock } })
        await assertMTA(actions(passAsync) { actions(passAsync) { mtaBlock } })
        await assertMTA(actions(pass) { actions(passAsync) { mtaBlock } })
        await assertMTA(
            actions(passWithEvent) { actions(passWithEvent) { mtaBlock } },
            expectedNodeOutput: eventOutput
        )
        
        await assertMTA(
            actions(passWithEventAsync) { actions(passWithEventAsync) { mtaBlock }},
            expectedNodeOutput: eventOutput
        )
        
        await assertMTA(
            actions(passWithEvent) { actions(passWithEventAsync) { mtaBlock }},
            expectedNodeOutput: eventOutput
        )
    }
}
