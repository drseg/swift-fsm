import XCTest
@testable import SwiftFSM

class MatchingBlockTests: BlockTestsBase {
    func mbnComponents(of s: Internal.Sentence) -> (MatchingBlockNode, MatchingBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any Node<DefaultIO>) -> MatchingBlockNode {
        n as! MatchingBlockNode
    }

    func assertMWTANode(
        _ b: MatchingBlockNode,
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
        _ b: MatchingBlockNode,
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
        _ b: MatchingBlockNode,
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
        _ b: MatchingBlockNode,
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
            _ b: Internal.MWTABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int = #line,
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

        assertMWTABlock(matching(Q.a) { mwtaBlock }, all: [Q.a])
        assertMWTABlock(matching(Q.a, and: R.a) { mwtaBlock }, all: [Q.a, R.a])
        assertMWTABlock(matching(Q.a, or: Q.b) { mwtaBlock }, any: [Q.a, Q.b])
        assertMWTABlock(matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock }, 
                        any: [Q.a, Q.b],
                        all: [R.a, S.a])
    }

    func testMWABlocks() {
        func assertMWABlock(
            _ b: Internal.MWABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMWANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mwaLine,
                          xctLine: xl)
        }

        assertMWABlock(matching(Q.a) { mwaBlock }, all: [Q.a])
        assertMWABlock(matching(Q.a, and: R.a) { mwaBlock }, all: [Q.a, R.a])
        assertMWABlock(matching(Q.a, or: Q.b) { mwaBlock }, any: [Q.a, Q.b])
        assertMWABlock(matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock }, 
                       any: [Q.a, Q.b],
                       all: [R.a, S.a])
    }

    func testMTABlocks() {
        func assertMTABlock(
            _ b: Internal.MTABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) {
            assertMTANode(mbn(b.node),
                          any: any,
                          all: all,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        assertMTABlock(matching(Q.a) { mtaBlock }, all: [Q.a])
        assertMTABlock(matching(Q.a, and: R.a) { mtaBlock }, all: [Q.a, R.a])
        assertMTABlock(matching(Q.a, or: Q.b) { mtaBlock }, any: [Q.a, Q.b])
        assertMTABlock(matching(Q.a, or: Q.b, and: R.a, S.a) { mtaBlock },
                       any: [Q.a, Q.b],
                       all: [R.a, S.a])
    }

    func testCompoundMWTABlocks() {
        func assertCompoundMWTABlock(
            _ b: Internal.MWTABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
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

        assertCompoundMWTABlock(matching(Q.a) { matching(Q.a) { mwtaBlock } }, all: [Q.a])
    }

    func testCompoundMWABlocks() {
        func assertCompoundMWABlock(
            _ b: Internal.MWABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
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

        assertCompoundMWABlock(matching(Q.a) { matching(Q.a) { mwaBlock } }, all: [Q.a])
    }

    func testCompoundMTABlocks() {
        func assertCompoundMTABlock(
            _ b: Internal.MTABlock,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
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

        assertCompoundMTABlock(matching(Q.a) { matching(Q.a) { mtaBlock } }, all: [Q.a])
    }
}
