import XCTest
@testable import SwiftFSM

class ConditionBlockTests: BlockTestsBase {
    func mbnComponents(of s: Sentence) -> (MatchBlockNode, MatchBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any Node<DefaultIO>) -> MatchBlockNode {
        n as! MatchBlockNode
    }

    @MainActor
    func assertMWTANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    @MainActor
    func assertMWANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    @MainActor
    func assertMTANode(
        _ b: MatchBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    @MainActor
    func assertMatchBlock(
        _ b: MatchBlockNode,
        expected: Bool,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "condition", sutLine: sl, xctLine: xl)
        assertMatchNode(b, condition: expected, caller: "condition", sutLine: sl, xctLine: xl)
    }

    @MainActor
    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            condition: Bool,
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(
                mbn(b.node),
                expected: condition,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        let l1 = #line; let c1 = condition({ false }) { mwtaBlock }
        assertMWTABlock(c1, condition: false, nodeLine: l1)
    }

    @MainActor
    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          expected: condition,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { mwaBlock }
        assertMWABlock(c1, condition: false, nodeLine: l1)
    }

    @MainActor
    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          expected: condition,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { mtaBlock }
        assertMTABlock(c1, condition: false, nodeLine: l1)
    }

    @MainActor
    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMWTANode(c.1,
                           expected: condition,
                           nodeLine: nl,
                           restLine: mwtaLine,
                           xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwtaBlock } }
        assertCompoundMWTABlock(c1, condition: false, nodeLine: l1)
    }

    @MainActor
    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMWANode(c.1,
                          expected: condition,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwaBlock } }
        assertCompoundMWABlock(c1, condition: false, nodeLine: l1)
    }

    @MainActor
    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            assertMTANode(c.1,
                          expected: condition,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mtaBlock } }
        assertCompoundMTABlock(c1, condition: false, nodeLine: l1)
    }
}
