import XCTest
@testable import SwiftFSM

class WhenBlockTests: BlockTestsBase {
    func assert(
        _ b: Syntax.MWTA_Group,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) async {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, xctLine: xl)
        await assertMTAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Syntax.MWA_Group,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) async {
        let wbn = b.node as! WhenBlockNode
        assertWhenNode(wbn, events: events, sutLine: nl, xctLine: xl)

        let actionsNode = wbn.rest.first as! ActionsNode
        await assertActions(actionsNode.actions, expectedOutput: eo, xctLine: xl)

        let matchNode = actionsNode.rest.first as! MatchingNode
        await assertMatchNode(matchNode, all: [P.a], sutFile: baseFile, sutLine: rl, xctLine: xl)
    }

    func testWhenBlockWithMTA() async {
        await assert(when(1, or: 2) { mtaBlock }, restLine: mtaLine)
        await assert(when(1) { mtaBlock }, events: [1], restLine: mtaLine)
    }

    func testWhenBlockWithMA() async {
        await assert(when(1, or: 2) { maBlock }, restLine: maLine)
        await assert(when(1) { maBlock }, events: [1], restLine: maLine)
    }
}
