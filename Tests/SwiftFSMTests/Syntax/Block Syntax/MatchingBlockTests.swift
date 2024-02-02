import XCTest
@testable import SwiftFSM

class MatchingBlockTests: BlockTestsBase {
    func mbnComponents(of s: Sentence) -> (MatchBlockNode, MatchBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any Node<DefaultIO>) -> MatchBlockNode {
        n as! MatchBlockNode
    }

    func assertMWTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) {
        assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMatchBlock(
        _ b: MatchBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) {
        assertNeverEmptyNode(b, caller: "matching", sutLine: sl, xctLine: xl)
        assertMatchNode(b, any: [any], all: all, sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() {
        func assertMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        let l1 = #line; let m1 = matching(Q.a) { mwtaBlock }
        assertMWTABlock(m1, all: [Q.a], nodeLine: l1)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwtaBlock }
        assertMWTABlock(m3, all: [Q.a, R.a], nodeLine: l3)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mwtaBlock }
        assertMWTABlock(m5, any: [Q.a, Q.b], nodeLine: l5)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock }
        assertMWTABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
    }

    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { mwaBlock }
        assertMWABlock(m1, all: [Q.a], nodeLine: l1)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mwaBlock }
        assertMWABlock(m3, all: [Q.a, R.a], nodeLine: l3)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mwaBlock }
        assertMWABlock(m5, any: [Q.a, Q.b], nodeLine: l5)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock }
        assertMWABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
    }

    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { mtaBlock }
        assertMTABlock(m1, all: [Q.a], nodeLine: l1)

        let l3 = #line; let m3 = matching(Q.a, and: R.a) { mtaBlock }
        assertMTABlock(m3, all: [Q.a, R.a], nodeLine: l3)

        let l5 = #line; let m5 = matching(Q.a, or: Q.b) { mtaBlock }
        assertMTABlock(m5, any: [Q.a, Q.b], nodeLine: l5)

        let l7 = #line; let m7 = matching(Q.a, or: Q.b, and: R.a, S.a)  { mtaBlock }
        assertMTABlock(m7, any: [Q.a, Q.b], all: [R.a, S.a], nodeLine: l7)
    }

    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWTANode(c.1,
                           any: any,
                           all: all,
                           nodeLine: nl,
                           restLine: mwtaLine,
                           xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwtaBlock } }
        assertCompoundMWTABlock(m1, all: [Q.a], nodeLine: l1)
    }

    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMWANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mwaBlock } }
        assertCompoundMWABlock(m1, all: [Q.a], nodeLine: l1)
    }

    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTASentence,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) {
            let c = mbnComponents(of: b)

            assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            assertMTANode(c.1,
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let m1 = matching(Q.a) { matching(Q.a) { mtaBlock } }
        assertCompoundMTABlock(m1, all: [Q.a], nodeLine: l1)
    }
}
