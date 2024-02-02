import XCTest
@testable import SwiftFSM

class ThenBlockTests: BlockTestsBase {
    func assert(
        _ b: Internal.MWTASentence,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        assertMWAResult(node.rest, sutLine: rl, xctLine: xl)
    }

    func assert(
        _ b: Internal.MTASentence,
        expectedOutput eo: String = BlockTestsBase.defaultOutput,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt = #line
    ) {
        let node = b.node as! ThenBlockNode
        assertThenNode(node, state: 1, sutFile: #file, sutLine: nl, xctLine: xl)
        assertMAResult(node.rest, expectedOutput: eo, sutLine: rl, xctLine: xl)
    }

    func testThenBlockWithMTA() {
        let l1 = #line; let t1 = then(1) { mwaBlock }
        assert(t1, nodeLine: l1, restLine: mwaLine)
    }

    func testThenBlockWithMA() {
        let l1 = #line; let w1 = then(1) { maBlockSync }
        assert(w1, nodeLine: l1, restLine: maLineSync)

        let l3 = #line; let w3 = then(1) { maBlockAsync }
        assert(w3, nodeLine: l3, restLine: maLineAsync)

        let l5 = #line; let w5 = then(1) { maBlockWithEventSync }
        assert(w5,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l5,
               restLine: maLineWithEventSync)

        let l7 = #line; let w7 = then(1) { maBlockWithEventAsync }
        assert(w7,
               expectedOutput: Self.defaultOutputWithEvent,
               nodeLine: l7,
               restLine: maLineWithEventAsync)
    }
}

