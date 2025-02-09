import XCTest
@testable import SwiftFSM

class ConditionBlockTests: BlockTestsBase {
    func mbnComponents(of s: Syntax.CompoundSyntax) -> (MatchingBlockNode, MatchingBlockNode) {
        let a1 = mbn(s.node)
        let a2 = mbn(a1.rest.first!)
        return (a1, a2)
    }

    func mbn(_ n: any SyntaxNode<RawSyntaxDTO>) -> MatchingBlockNode {
        n as! MatchingBlockNode
    }

    func assertMWTANode(
        _ b: MatchingBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        await assertMWTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMWANode(
        _ b: MatchingBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        await assertMWAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMTANode(
        _ b: MatchingBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        xctLine xl: UInt
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, xctLine: xl)
        await assertMTAResult(b.rest, sutLine: rl, xctLine: xl)
    }

    func assertMatchBlock(
        _ b: MatchingBlockNode,
        expected: Bool,
        sutLine sl: Int,
        xctLine xl: UInt = #line
    ) async {
        assertNeverEmptyNode(b, caller: "condition", sutLine: sl, xctLine: xl)
        await assertMatchNode(b, condition: expected, caller: "condition", sutLine: sl, xctLine: xl)
    }

    func testMWTABlocks() async {
        func assertMWTABlock(
            _ b: Syntax.MWTA_Group,
            condition: Bool,
            nodeLine sl: Int,
            xctLine xl: UInt = #line
        ) async {
            await assertMWTANode(
                mbn(b.node),
                expected: condition,
                nodeLine: sl,
                restLine: mwtaLine,
                xctLine: xl
            )
        }

        let l1 = #line; let c1 = condition({ false }) { mwtaBlock }
        await assertMWTABlock(c1, condition: false, nodeLine: l1)
    }

    func testMWABlocks() async {
        func assertMWABlock(
            _ b: Syntax.MWA_Group,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) async {
            await assertMWANode(mbn(b.node),
                                expected: condition,
                                nodeLine: nl,
                                restLine: mwaLine,
                                xctLine: xl)
        }
        
        let l1 = #line; let c1 = condition({ false }) { mwaBlock }
        await assertMWABlock(c1, condition: false, nodeLine: l1)
    }

    func testMTABlocks() async {
        func assertMTABlock(
            _ b: Syntax.MTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) async {
            await assertMTANode(mbn(b.node),
                          expected: condition,
                          nodeLine: nl,
                          restLine: mtaLine,
                          xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { mtaBlock }
        await assertMTABlock(c1, condition: false, nodeLine: l1)
    }

    func testCompoundMWTABlocks() async {
        func assertCompoundMWTABlock(
            _ b: Syntax.MWTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)

            await assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            await assertMWTANode(c.1,
                           expected: condition,
                           nodeLine: nl,
                           restLine: mwtaLine,
                           xctLine: xl)
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwtaBlock } }
        await assertCompoundMWTABlock(c1, condition: false, nodeLine: l1)
    }
    
    func testCompoundMWABlocks() async {
        func assertCompoundMWABlock(
            _ b: Syntax.MWA_Group,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            await assertMWANode(c.1,
                                expected: condition,
                                nodeLine: nl,
                                restLine: mwaLine,
                                xctLine: xl)
        }
        
        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwaBlock } }
        await assertCompoundMWABlock(c1, condition: false, nodeLine: l1)
    }

    func testCompoundMTABlocks() async {
        func assertCompoundMTABlock(
            _ b: Syntax.MTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            xctLine xl: UInt = #line
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, expected: condition, sutLine: nl, xctLine: xl)
            await assertMTANode(c.1,
                                expected: condition,
                                nodeLine: nl,
                                restLine: mtaLine,
                                xctLine: xl)
        }
        
        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mtaBlock } }
        await assertCompoundMTABlock(c1, condition: false, nodeLine: l1)
    }
}
