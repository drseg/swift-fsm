import XCTest
@testable import SwiftFSM

class BuilderTests: BlockTestsBase {
    func testMWTA() async {
        let line = #line; @MWTABuilder var mwta: [Syntax.MatchingWhenThenActions] {
            matching(P.a) | when(1, or: 2) | then(1) | pass
                            when(1, or: 2) | then(1) | pass
            matching(P.a) | when(1, or: 2) | then(1) | passAsync
                            when(1, or: 2) | then(1) | passAsync
            matching(P.a) | when(1, or: 2) | then(1) | passWithEvent
                            when(1, or: 2) | then(1) | passWithEvent
            matching(P.a) | when(1, or: 2) | then(1) | passWithEventAsync
                            when(1, or: 2) | then(1) | passWithEventAsync
            matching(P.a) | when(1, or: 2) | then(1) | pass & pass
                            when(1, or: 2) | then(1) | pass & pass
        }
        
        await assertMWTA(mwta[0].node, sutLine: line + 1)
        await assertWTA(mwta[1].node, sutLine: line + 2)
        
        await assertMWTA(mwta[2].node, sutLine: line + 3)
        await assertWTA(mwta[3].node, sutLine: line + 4)
        
        await assertMWTA(mwta[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        await assertWTA(
            mwta[5].node,
            expectedOutput: Self.defaultOutputWithEvent,
            sutLine: line + 6
        )
        
        await assertMWTA(mwta[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        await assertWTA(
            mwta[7].node,
            expectedOutput: Self.defaultOutputWithEvent,
            sutLine: line + 8
        )
        
        await assertMWTA(mwta[8].node,
                         expectedOutput: Self.defaultOutput + Self.defaultOutput,
                         sutLine: line + 9)
        await assertWTA(mwta[9].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 10)
    }

    func testMWA() async {
        let line = #line; @MWABuilder var mwa: [Syntax.MatchingWhenActions] {
            matching(P.a) | when(1, or: 2) | pass
                            when(1, or: 2) | pass
            matching(P.a) | when(1, or: 2) | passAsync
                            when(1, or: 2) | passAsync
            matching(P.a) | when(1, or: 2) | passWithEvent
                            when(1, or: 2) | passWithEvent
            matching(P.a) | when(1, or: 2) | passWithEventAsync
                            when(1, or: 2) | passWithEventAsync
            matching(P.a) | when(1, or: 2) | pass & pass
                            when(1, or: 2) | pass & pass
        }

        await assertMWA(mwa[0].node, sutLine: line + 1)
        await assertWA(mwa[1].node, sutLine: line + 2)

        await assertMWA(mwa[2].node, sutLine: line + 3)
        await assertWA(mwa[3].node, sutLine: line + 4)

        await assertMWA(mwa[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        await assertWA(mwa[5].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 6)

        await assertMWA(mwa[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        await assertWA(mwa[7].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 8)

        await assertMWA(mwa[8].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 9)
        await assertWA(mwa[9].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 10)
    }

    func testMTA() async {
        let line = #line; @MTABuilder var mta: [Syntax.MatchingThenActions] {
            matching(P.a) | then(1) | pass
                            then(1) | pass
            matching(P.a) | then(1) | passAsync
                            then(1) | passAsync
            matching(P.a) | then(1) | passWithEvent
                            then(1) | passWithEvent
            matching(P.a) | then(1) | passWithEventAsync
                            then(1) | passWithEventAsync
            matching(P.a) | then(1) | pass & pass
                            then(1) | pass & pass
        }

        await assertMTA(mta[0].node, sutLine: line + 1)
        await assertTA(mta[1].node, sutLine: line + 2)

        await assertMTA(mta[2].node, sutLine: line + 3)
        await assertTA(mta[3].node, sutLine: line + 4)

        await assertMTA(mta[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        await assertTA(mta[5].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 6)

        await assertMTA(mta[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        await assertTA(mta[7].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 8)

        await assertMTA(mta[8].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 9)
        await assertTA(mta[9].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 10)
    }

    func testMA() async {
        let line = #line; @MABuilder var ma: [Syntax.MatchingActions] {
            matching(P.a) | pass
            matching(P.a) | passAsync
            matching(P.a) | passWithEvent
            matching(P.a) | passWithEventAsync
            matching(P.a) | pass & pass
        }

        await assertMA(ma[0].node, sutLine: line + 1)
        await assertMA(ma[1].node, sutLine: line + 2)
        await assertMA(ma[2].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 3)
        await assertMA(ma[3].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 4)
        await assertMA(ma[4].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 5)
    }
}
