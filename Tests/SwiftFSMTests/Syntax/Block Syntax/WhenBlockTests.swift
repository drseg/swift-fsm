import XCTest
@testable import SwiftFSM

class WhenBlockTests: BlockTestsBase {
    func assert(
        _ b: Internal.MWTASentence,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.whenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        assertMTAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Internal.MWASentence,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        #warning("use of defaultFile here highlights nasty file handling in all related tests")
        let node = b.whenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)

        let actionsNode = node.rest.first as! ActionsNode
        assertActions(actionsNode.actions, expectedOutput: eo, xctLine: xl)

        let matchNode = actionsNode.rest.first as! MatchNode
        assertMatchNode(matchNode, all: [P.a], sutFile: defaultFile, sutLine: rl, xctLine: xl)
    }

    func testWhenBlockWithMTA() {
        assert(when(1, or: 2) { mtaBlock }, restLine: mtaLine)
        assert(when(1) { mtaBlock }, events: [1], restLine: mtaLine)
    }

    func testWhenBlockWithMA() {
        assert(when(1, or: 2) { maBlock }, restLine: maLine)
        assert(when(1) { maBlock }, events: [1], restLine: maLine)
    }
}

private extension BlockSentence {
    var whenBlockNode: WhenBlockNode {
        node as! WhenBlockNode
    }
}
