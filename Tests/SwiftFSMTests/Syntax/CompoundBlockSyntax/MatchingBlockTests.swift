import XCTest
@testable import SwiftFSM

class MatchingBlockTests: BlockTestsBase {
    func mbnComponents(of s: Syntax.CompoundSyntax) -> (MatchingBlockNode, MatchingBlockNode) {
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
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        await assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        await assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, xctLine: xl)
        await assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMatchBlock(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        assertNeverEmptyNode(b, caller: "matching", sutLine: sl, xctLine: xl)
        await assertMatchNode(b, any: [any], all: all, sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() async {
        func assertMWTABlock(
            _ b: Syntax.MWTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int = #line,
            xctLine xl: UInt = #line
        ) async  {
            await assertMWTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }
        
        await assertMWTABlock(matching(Q.a) { mwtaBlock }, all: [Q.a])
        await assertMWTABlock(matching(Q.a, and: R.a) { mwtaBlock }, all: [Q.a, R.a])
        await assertMWTABlock(matching(Q.a, or: Q.b) { mwtaBlock }, any: [Q.a, Q.b])
        await assertMWTABlock(matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock },
                              any: [Q.a, Q.b],
                              all: [R.a, S.a])
    }

    func testMWABlocks() async {
        func assertMWABlock(
            _ b: Syntax.MWA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            await assertMWANode(mbn(b.node),
                                any: any,
                                all: all,
                                nodeLine: nl,
                                restLine: mwaLine,
                                xctLine: xl)
        }
        
        await assertMWABlock(matching(Q.a) { mwaBlock }, all: [Q.a])
        await assertMWABlock(matching(Q.a, and: R.a) { mwaBlock }, all: [Q.a, R.a])
        await assertMWABlock(matching(Q.a, or: Q.b) { mwaBlock }, any: [Q.a, Q.b])
        await assertMWABlock(matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock },
                             any: [Q.a, Q.b],
                             all: [R.a, S.a])
    }
    
    func testMTABlocks() async {
        func assertMTABlock(
            _ b: Syntax.MTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            await assertMTANode(mbn(b.node),
                                any: any,
                                all: all,
                                nodeLine: nl,
                                restLine: mtaLine,
                                xctLine: xl)
        }
        
        await assertMTABlock(matching(Q.a, or: Q.b, and: R.a, S.a) { mtaBlock },
                             any: [Q.a, Q.b],
                             all: [R.a, S.a])
    }
    
    func testCompoundMWTABlocks() async {
        func assertCompoundMWTABlock(
            _ b: Syntax.MWTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            await assertMWTANode(
                c.1,
                any: any,
                all: all,
                nodeLine: nl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        await assertCompoundMWTABlock(matching(Q.a) { matching(Q.a) { mwtaBlock } }, all: [Q.a])
    }

    func testCompoundMWABlocks() async {
        func assertCompoundMWABlock(
            _ b: Syntax.MWA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            await assertMWANode(
                c.1,
                any: any,
                all: all,
                nodeLine: nl,
                restLine: mwaLine,
                xctLine: xl
            )
        }

        await assertCompoundMWABlock(matching(Q.a) { matching(Q.a) { mwaBlock } }, all: [Q.a])
    }

    func testCompoundMTABlocks() async {
        func assertCompoundMTABlock(
            _ b: Syntax.MTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, any: any, all: all, sutLine: nl, xctLine: xl)
            await assertMTANode(
                c.1,
                any: any,
                all: all,
                nodeLine: nl,
                restLine: mtaLine,
                xctLine: xl
            )
        }

        await assertCompoundMTABlock(matching(Q.a) { matching(Q.a) { mtaBlock } }, all: [Q.a])
    }
}
