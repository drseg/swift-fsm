import XCTest
@testable import SwiftFSM

class BuilderTests: BlockTestsBase {
    @MainActor
    func testMWTA() {
        let line = #line; @MWTABuilder var mwta: [MWTA] {
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

        assertMWTA(mwta[0].node, sutLine: line + 1)
        assertWTA(mwta[1].node, sutLine: line + 2)

        assertMWTA(mwta[2].node, sutLine: line + 3)
        assertWTA(mwta[3].node, sutLine: line + 4)

        assertMWTA(mwta[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        assertWTA(mwta[5].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 6)

        assertMWTA(mwta[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        assertWTA(mwta[7].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 8)

        assertMWTA(mwta[8].node,
                   expectedOutput: Self.defaultOutput + Self.defaultOutput,
                   sutLine: line + 9)
        assertWTA(mwta[9].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 10)
    }

    @MainActor
    func testMWA() {
        let line = #line; @MWABuilder var mwa: [MWA] {
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

        assertMWA(mwa[0].node, sutLine: line + 1)
        assertWA(mwa[1].node, sutLine: line + 2)

        assertMWA(mwa[2].node, sutLine: line + 3)
        assertWA(mwa[3].node, sutLine: line + 4)

        assertMWA(mwa[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        assertWA(mwa[5].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 6)

        assertMWA(mwa[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        assertWA(mwa[7].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 8)

        assertMWA(mwa[8].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 9)
        assertWA(mwa[9].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 10)
    }

    @MainActor
    func testMTA() {
        let line = #line; @MTABuilder var mta: [MTA] {
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

        assertMTA(mta[0].node, sutLine: line + 1)
        assertTA(mta[1].node, sutLine: line + 2)

        assertMTA(mta[2].node, sutLine: line + 3)
        assertTA(mta[3].node, sutLine: line + 4)

        assertMTA(mta[4].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 5)
        assertTA(mta[5].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 6)

        assertMTA(mta[6].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 7)
        assertTA(mta[7].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 8)

        assertMTA(mta[8].node,
                  expectedOutput: Self.defaultOutput + Self.defaultOutput,
                  sutLine: line + 9)
        assertTA(mta[9].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 10)
    }

    @MainActor
    func testMA() {
        let line = #line; @MABuilder var ma: [MA] {
            matching(P.a) | pass
            matching(P.a) | passAsync
            matching(P.a) | passWithEvent
            matching(P.a) | passWithEventAsync
            matching(P.a) | pass & pass
        }

        assertMA(ma[0].node, sutLine: line + 1)
        assertMA(ma[1].node, sutLine: line + 2)
        assertMA(ma[2].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 3)
        assertMA(ma[3].node, expectedOutput: Self.defaultOutputWithEvent, sutLine: line + 4)
        assertMA(ma[4].node,
                 expectedOutput: Self.defaultOutput + Self.defaultOutput,
                 sutLine: line + 5)
    }
}
