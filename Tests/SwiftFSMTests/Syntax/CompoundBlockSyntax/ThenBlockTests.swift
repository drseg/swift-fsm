import Testing
@testable import SwiftFSM

class ThenBlockTests: BlockTestsBase {
    @Test func ThenBlockWithMTA() async {
        let node = (then(1) { mwaBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        await assertMWAResult(node.rest, sutLine: mwaLine)
    }

    @Test func ThenBlockWithMA() async {
        let node = (then(1) { maBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        await assertMAResult(node.rest, sutLine: maLine)
    }
}

private extension Syntax.CompoundSyntaxGroup {
    var thenBlockNode: ThenBlockNode {
        node as! ThenBlockNode
    }
}

