import XCTest
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: MRNTestBase {
    typealias LMRN = LazyMatchResolvingNode
    
    func makeSUT(rest: [any SyntaxNode<DefineNode.Output>]) -> LMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    func assertNotMatchClash(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        line: UInt = #line
    ) async {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        
        let p1 = m1.combineAnyAndAll().first ?? []
        let p2 = m2.combineAnyAndAll().first ?? []
        
        let result = makeSUT(rest: [d1, d2]).resolve()
        
        guard
            assertCount(result.errors, expected: 0, line: line),
            assertCount(result.output, expected: 2, line: line)
        else { return }
        
        await assertEqual(
            makeOutput(c: nil, g: s1, m: m1, p: p1, w: e1, t: s2),
            result.output.first,
            line: line
        )
        
        await assertEqual(
            makeOutput(c: nil, g: s1, m: m2, p: p2, w: e1, t: s3),
            result.output.last,
            line: line
        )
    }
    
    func assertMatchClash(_ m1: MatchDescriptorChain, _ m2: MatchDescriptorChain, line: UInt = #line) {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        let finalised = makeSUT(rest: [d1, d2]).resolve()
        
        guard
            assertCount(finalised.output, expected: 0, line: line),
            assertCount(finalised.errors, expected: 1, line: line)
        else { return }
        
        XCTAssert(finalised.errors.first is EMRN.ImplicitClashesError, line: line)
    }
    
    func testInit() async {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let rest = SVN(rest: [ARN(rest: [defineNode(s1, m1, e1, s2)])])
        await assertEqualFileAndLine(rest, sut.rest.first!)
    }
    
    func testEmptyMatchOutput() async {
        let sut = makeSUT(rest: [defineNode(s1, MatchDescriptorChain(), e1, s2)])
        let result = sut.resolve()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        await assertEqual(
            makeOutput(
                c: nil, g: s1, m: MatchDescriptorChain(), p: [], w: e1, t: s2
            ),
            result.output.first
        )
    }

    func testPredicateMatchOutput() async {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let result = sut.resolve()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        await assertEqual(
            makeOutput(
                g: s1, m: m1, p: [P.a, Q.a], w: e1, t: s2
            ),
            result.output.first
        )
    }
    
    func testImplicitMatchClashes() async {
        await assertNotMatchClash(MatchDescriptorChain(), MatchDescriptorChain(all: P.a))
        await assertNotMatchClash(MatchDescriptorChain(), MatchDescriptorChain(all: P.a, Q.a))
        await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: Q.a, S.a))

        await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: P.b))
        await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: P.b, Q.b))
        await assertNotMatchClash(MatchDescriptorChain(all: P.a, Q.a), MatchDescriptorChain(all: P.b, Q.b))
      
        assertMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: Q.a))
        assertMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(any: Q.a))
        assertMatchClash(MatchDescriptorChain(all: P.a, R.a), MatchDescriptorChain(all: Q.a, S.a))
    }
}
