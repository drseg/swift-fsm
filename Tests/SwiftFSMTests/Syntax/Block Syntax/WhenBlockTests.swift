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
        assert(w1, nodeLine: l1, restLine: mtaLine)

        let l3 = #line; let w3 = when(1) { mtaBlock }
        assert(w3, events: [1], nodeLine: l3, restLine: mtaLine)
    }

    func testWhenBlockWithMA() {
        let l1 = #line; let w1 = when(1, or: 2) { maBlock }
        assert(w1, nodeLine: l1, restLine: maLine)

        let l3 = #line; let w3 = when(1) { maBlock }
        assert(w3, events: [1], nodeLine: l3, restLine: maLine)
    }
}
