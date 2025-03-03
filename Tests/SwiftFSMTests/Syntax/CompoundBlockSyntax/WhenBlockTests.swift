import Testing
@testable import SwiftFSM

class WhenBlockTests: BlockTestsBase {
    func assert(
        _ b: Syntax.MWTA_Group,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let node = b.node as! WhenBlockNode
        assertWhenNode(node, events: events, sutLine: nl, location: location)
        await assertMTAResult(node.rest, sutLine: rl, location: location)
    }

    func assert(
        _ b: Syntax.MWA_Group,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        events: [Int] = [1, 2],
        nodeLine nl: Int = #line,
        restLine rl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        let wbn = b.node as! WhenBlockNode
        assertWhenNode(wbn, events: events, sutLine: nl, location: location)

        let actionsNode = wbn.rest.first as! ActionsNode
        await assertActions(actionsNode.actions, expectedOutput: eo, location: location)

        let matchNode = actionsNode.rest.first as! MatchingNode
        await assertMatchNode(
            matchNode,
            all: [P.a],
            sutFile: baseFile,
            sutLine: rl,
            location: location
        )
    }

    @Test func whenBlockWithMTA() async {
        await assert(when(1, or: 2) { mtaBlock }, restLine: mtaLine)
        await assert(when(1) { mtaBlock }, events: [1], restLine: mtaLine)
    }

    @Test func whenBlockWithMA() async {
        await assert(when(1, or: 2) { maBlock }, restLine: maLine)
        await assert(when(1) { maBlock }, events: [1], restLine: maLine)
    }
}
