import XCTest
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: MRNTestBase {
    typealias LMRN = LazyMatchResolvingNode
    
    func makeSUT(rest: [any Node<DefineNode.Output>]) -> LMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    @MainActor
    func assertNotMatchClash(_ m1: MatchDescriptor, _ m2: MatchDescriptor, line: UInt = #line) {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        
        let p1 = m1.combineAnyAndAll().first ?? []
        let p2 = m2.combineAnyAndAll().first ?? []
        
        let result = makeSUT(rest: [d1, d2]).resolved()
        
        guard
            assertCount(result.errors, expected: 0, line: line),
            assertCount(result.output, expected: 2, line: line)
        else { return }
        
        assertEqual(makeOutput(c: nil, g: s1, m: m1, p: p1, w: e1, t: s2),
                    result.output.first,
                    line: line)
        
        assertEqual(makeOutput(c: nil, g: s1, m: m2, p: p2, w: e1, t: s3),
                    result.output.last,
                    line: line)
    }
    
    func assertMatchClash(_ m1: MatchDescriptor, _ m2: MatchDescriptor, line: UInt = #line) {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        let finalised = makeSUT(rest: [d1, d2]).resolved()
        
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
    
    @MainActor
    func testEmptyMatchOutput() {
        let sut = makeSUT(rest: [defineNode(s1, MatchDescriptor(), e1, s2)])
        let result = sut.resolved()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        assertEqual(makeOutput(c: nil, g: s1, m: MatchDescriptor(), p: [], w: e1, t: s2),
                    result.output.first)
    }

    @MainActor
    func testPredicateMatchOutput() {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let result = sut.resolved()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        assertEqual(makeOutput(g: s1, m: m1, p: [P.a, Q.a], w: e1, t: s2),
                    result.output.first)
    }
    
    @MainActor
    func testImplicitMatchClashes() {
        assertNotMatchClash(MatchDescriptor(), MatchDescriptor(all: P.a))
        assertNotMatchClash(MatchDescriptor(), MatchDescriptor(all: P.a, Q.a))
        assertNotMatchClash(MatchDescriptor(all: P.a), MatchDescriptor(all: Q.a, S.a))
        
        assertNotMatchClash(MatchDescriptor(all: P.a), MatchDescriptor(all: P.b))
        assertNotMatchClash(MatchDescriptor(all: P.a), MatchDescriptor(all: P.b, Q.b))
        assertNotMatchClash(MatchDescriptor(all: P.a, Q.a), MatchDescriptor(all: P.b, Q.b))
                
        assertMatchClash(MatchDescriptor(all: P.a), MatchDescriptor(all: Q.a))
        assertMatchClash(MatchDescriptor(all: P.a), MatchDescriptor(any: Q.a))
        assertMatchClash(MatchDescriptor(all: P.a, R.a), MatchDescriptor(all: Q.a, S.a))
    }
}
