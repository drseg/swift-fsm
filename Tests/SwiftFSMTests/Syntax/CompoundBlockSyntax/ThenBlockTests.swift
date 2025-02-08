import XCTest
@testable import SwiftFSM

class ThenBlockTests: BlockTestsBase {
    func testThenBlockWithMTA() async {
        let node = (then(1) { mwaBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        await assertMWAResult(node.rest, sutLine: mwaLine)
    }

    func testThenBlockWithMA() async {
        let node = (then(1) { maBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        await assertMAResult(node.rest, sutLine: maLine)
    }
}

private extension Syntax.CompoundBlockSyntax {
    var thenBlockNode: ThenBlockNode {
        node as! ThenBlockNode
    }
}

