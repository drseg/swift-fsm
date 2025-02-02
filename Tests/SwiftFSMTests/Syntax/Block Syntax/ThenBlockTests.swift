import XCTest
@testable import SwiftFSM

class ThenBlockTests: BlockTestsBase {
    func testThenBlockWithMTA() {
        let node = (then(1) { mwaBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        assertMWAResult(node.rest, sutLine: mwaLine)
    }

    func testThenBlockWithMA() {
        let node = (then(1) { maBlock }).thenBlockNode; let line = #line
        assertThenNode(node, state: 1, sutFile: #file, sutLine: line)
        assertMAResult(node.rest, sutLine: maLine)
    }
}

private extension Internal.BlockSentence {
    var thenBlockNode: ThenBlockNode {
        node as! ThenBlockNode
    }
}

