import XCTest
@testable import SwiftFSM

class WhenBlockTests: BlockTestsBase {
    func assert(
        _ b: Internal.MWTASentence,
        events: [Int] = [1, 2],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        assertMTAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Internal.MWASentence,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        events: [Int] = [1, 2],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        #warning("use of defaultFile here highlights nasty file handling in all related tests")
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        let actionsNode = node.rest.first as! ActionsNode
        assertActions(actionsNode.actions, expectedOutput: eo, xctLine: xl)
        let matchNode = actionsNode.rest.first as! MatchNode
        assertMatchNode(matchNode, all: [P.a], sutFile: defaultFile, sutLine: rl, xctLine: xl)
    }

    func testWhenBlockWithMTA() {
        let l1 = #line; let w1 = when(1, or: 2) { mtaBlock }
        let l2 = #line; let w2 = When(1, or: 2) { mtaBlock }

        assert(w1, nodeLine: l1, restLine: mtaLine)
        assert(w2, nodeLine: l2, restLine: mtaLine)

        let l3 = #line; let w3 = when(1) { mtaBlock }
        let l4 = #line; let w4 = When(1) { mtaBlock }

        assert(w3, events: [1], nodeLine: l3, restLine: mtaLine)
        assert(w4, events: [1], nodeLine: l4, restLine: mtaLine)
    }

    func testWhenBlockWithMA() {
        let l1 = #line; let w1 = when(1, or: 2) { maBlockSync }
        let l2 = #line; let w2 = When(1, or: 2) { maBlockSync }

        assert(w1, nodeLine: l1, restLine: maLineSync)
        assert(w2, nodeLine: l2, restLine: maLineSync)

        let l3 = #line; let w3 = when(1) { maBlockSync }
        let l4 = #line; let w4 = When(1) { maBlockSync }

        assert(w3, events: [1], nodeLine: l3, restLine: maLineSync)
        assert(w4, events: [1], nodeLine: l4, restLine: maLineSync)

        let l5 = #line; let w5 = when(1, or: 2) { maBlockWithEventSync }
        let l6 = #line; let w6 = When(1, or: 2) { maBlockWithEventSync }

        assert(w5,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l5,
               restLine: maLineWithEventSync)
        assert(w6,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l6,
               restLine: maLineWithEventSync)

        let l7 = #line; let w7 = when(1) { maBlockWithEventSync }
        let l8 = #line; let w8 = When(1) { maBlockWithEventSync }

        assert(w7,
               expectedOutput: Self.defaultOutputWithEvent,
               events: [1],
               nodeLine: l7,
               restLine: maLineWithEventSync)
        assert(w8,
               expectedOutput: Self.defaultOutputWithEvent,
               events: [1],
               nodeLine: l8,
               restLine: maLineWithEventSync)
    }
}
