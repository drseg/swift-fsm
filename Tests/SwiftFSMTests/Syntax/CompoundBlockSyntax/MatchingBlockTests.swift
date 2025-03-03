import Testing
@testable import SwiftFSM

class MatchingBlockTests: BlockTestsBase {
    @Test func mwtaBlocks() async {
        func assertMWTABlock(
            _ b: Syntax.MWTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine sl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async  {
            await assertMWTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: sl,
                restLine: mwtaLine,
                location: location
            )
        }
        
        await assertMWTABlock(
            matching(Q.a) { mwtaBlock },
            all: [Q.a]
        )
        
        await assertMWTABlock(
            matching(Q.a, and: R.a) { mwtaBlock },
            all: [Q.a, R.a]
        )
        
        await assertMWTABlock(
            matching(Q.a, or: Q.b) { mwtaBlock },
            any: [Q.a, Q.b]
        )
        
        await assertMWTABlock(
            matching(Q.a, or: Q.b, and: R.a, S.a) { mwtaBlock },
            any: [Q.a, Q.b],
            all: [R.a, S.a]
        )
    }

    @Test func mwaBlocks() async {
        func assertMWABlock(
            _ b: Syntax.MWA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMWANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: nl,
                restLine: mwaLine,
                location: location
            )
        }
        
        await assertMWABlock(
            matching(Q.a) { mwaBlock },
            all: [Q.a]
        )
        
        await assertMWABlock(
            matching(Q.a, and: R.a) { mwaBlock },
            all: [Q.a, R.a]
        )
        
        await assertMWABlock(
            matching(Q.a, or: Q.b) { mwaBlock },
            any: [Q.a, Q.b]
        )
        
        await assertMWABlock(
            matching(Q.a, or: Q.b, and: R.a, S.a)  { mwaBlock },
            any: [Q.a, Q.b],
            all: [R.a, S.a]
        )
    }
    
    @Test func mtaBlocks() async {
        func assertMTABlock(
            _ b: Syntax.MTA_Group,
            any: [any Predicate] = [],
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            await assertMTANode(
                mbn(b.node),
                any: any,
                all: all,
                nodeLine: nl,
                restLine: mtaLine,
                location: location
            )
        }
        
        await assertMTABlock(
            matching(Q.a, or: Q.b, and: R.a, S.a) { mtaBlock },
            any: [Q.a, Q.b],
            all: [R.a, S.a]
        )
    }
    
    @Test func compoundMWTABlocks() async {
        func assertCompoundMWTABlock(
            _ b: Syntax.MWTA_Group,
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(
                c.0,
                any: [],
                all: all,
                sutLine: nl,
                location: location
            )
            
            await assertMWTANode(
                c.1,
                any: [],
                all: all,
                nodeLine: nl,
                restLine: mwtaLine,
                location: location
            )
        }

        await assertCompoundMWTABlock(matching(Q.a) { matching(Q.a) { mwtaBlock } }, all: [Q.a])
    }

    @Test func compoundMWABlocks() async {
        func assertCompoundMWABlock(
            _ b: Syntax.MWA_Group,
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(
                c.0,
                any: [],
                all: all,
                sutLine: nl,
                location: location
            )
            
            await assertMWANode(
                c.1,
                any: [],
                all: all,
                nodeLine: nl,
                restLine: mwaLine,
                location: location
            )
        }

        await assertCompoundMWABlock(matching(Q.a) { matching(Q.a) { mwaBlock } }, all: [Q.a])
    }

    @Test func compoundMTABlocks() async {
        func assertCompoundMTABlock(
            _ b: Syntax.MTA_Group,
            all: [any Predicate] = [],
            nodeLine nl: Int = #line,
            location: SourceLocation = #_sourceLocation
        ) async {
            let c = mbnComponents(of: b)
            
            await assertMatchBlock(
                c.0,
                any: [],
                all: all,
                sutLine: nl,
                location: location
            )
            
            await assertMTANode(
                c.1,
                any: [],
                all: all,
                nodeLine: nl,
                restLine: mtaLine,
                location: location
            )
        }

        await assertCompoundMTABlock(matching(Q.a) { matching(Q.a) { mtaBlock } }, all: [Q.a])
    }
    
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
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, location: location)
        await assertMWTAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMWANode(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, location: location)
        await assertMWAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMTANode(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        nodeLine nl: Int,
        restLine rl: Int,
        location: SourceLocation
    ) async {
        await assertMatchBlock(b, any: any, all: all, sutLine: nl, location: location)
        await assertMTAResult(b.rest, sutLine: rl, location: location)
    }

    func assertMatchBlock(
        _ b: MatchingBlockNode,
        any: [any Predicate],
        all: [any Predicate],
        sutLine sl: Int,
        location: SourceLocation = #_sourceLocation
    ) async {
        assertNeverEmptyNode(b, caller: "matching", sutLine: sl, location: location)
        await assertMatchNode(b, any: [any], all: all, sutLine: sl, location: location)
    }
}
