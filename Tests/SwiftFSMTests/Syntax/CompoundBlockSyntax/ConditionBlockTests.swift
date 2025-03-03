import Testing
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
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, location: location)
        await assertMWTAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMWANode(
        _ b: MatchingBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, location: location)
        await assertMWAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMTANode(
        _ b: MatchingBlockNode,
        expected: Bool,
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, expected: expected, sutLine: nl, location: location)
        await assertMTAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMatchBlock(
        _ b: MatchingBlockNode,
        expected: Bool,
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        assertNeverEmptyNode(b, caller: "condition", sutLine: sl, location: location)
        await assertMatchNode(
            b,
            condition: expected,
            caller: "condition",
            sutLine: sl,
            location: location
        )
    }

    @Test func mwtaBlocks() async {
        func assertMWTABlock(
            _ b: Syntax.MWTA_Group,
            condition: Bool,
            nodeLine sl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMWTANode(
                mbn(b.node),
                expected: condition,
                nodeLine: sl,
                restLine: mwtaLine,
                location: location
            )
        }

        let l1 = #line; let c1 = condition({ false }) { mwtaBlock }
        await assertMWTABlock(c1, condition: false, nodeLine: l1)
    }

    @Test func mwaBlocks() async {
        func assertMWABlock(
            _ b: Syntax.MWA_Group,
            condition: Bool,
            nodeLine nl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMWANode(
                mbn(b.node),
                expected: condition,
                nodeLine: nl,
                restLine: mwaLine,
                location: location
            )
        }
        
        let l1 = #line; let c1 = condition({ false }) { mwaBlock }
        await assertMWABlock(c1, condition: false, nodeLine: l1)
    }

    @Test func mtaBlocks() async {
        func assertMTABlock(
            _ b: Syntax.MTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMTANode(
                mbn(b.node),
                expected: condition,
                nodeLine: nl,
                restLine: mtaLine,
                location: location
            )
        }

        let l1 = #line; let c1 = condition({ false }) { mtaBlock }
        await assertMTABlock(c1, condition: false, nodeLine: l1)
    }

    @Test func compoundMWTABlocks() async {
        func assertCompoundMWTABlock(
            _ b: Syntax.MWTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)

            await assertMatchBlock(c.0, expected: condition, sutLine: nl, location: location)
            await assertMWTANode(
                c.1,
                expected: condition,
                nodeLine: nl,
                restLine: mwtaLine,
                location: location
            )
        }

        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwtaBlock } }
        await assertCompoundMWTABlock(c1, condition: false, nodeLine: l1)
    }
    
    @Test func compoundMWABlocks() async {
        func assertCompoundMWABlock(
            _ b: Syntax.MWA_Group,
            condition: Bool,
            nodeLine nl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, expected: condition, sutLine: nl, location: location)
            await assertMWANode(
                c.1,
                expected: condition,
                nodeLine: nl,
                restLine: mwaLine,
                location: location
            )
        }
        
        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mwaBlock } }
        await assertCompoundMWABlock(c1, condition: false, nodeLine: l1)
    }

    @Test func compoundMTABlocks() async {
        func assertCompoundMTABlock(
            _ b: Syntax.MTA_Group,
            condition: Bool,
            nodeLine nl: Int,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(c.0, expected: condition, sutLine: nl, location: location)
            await assertMTANode(
                c.1,
                expected: condition,
                nodeLine: nl,
                restLine: mtaLine,
                location: location
            )
        }
        
        let l1 = #line; let c1 = condition({ false }) { condition({ false }) { mtaBlock } }
        await assertCompoundMTABlock(c1, condition: false, nodeLine: l1)
    }
}
