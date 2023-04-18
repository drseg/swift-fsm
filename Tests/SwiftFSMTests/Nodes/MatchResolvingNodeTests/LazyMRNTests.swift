import XCTest
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: MRNTestBase {
    typealias LMRN = LazyMatchResolvingNode
    
    func makeSUT(rest: [any Node<DefineNode.Output>]) -> LMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    func assertNotMatchClash(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        let sut = makeSUT(rest: [d1, d2])
        let result = sut.finalised()
        
        guard
            assertCount(result.errors, expected: 0, line: line),
            assertCount(result.output, expected: 2, line: line)
        else { return }
        
        assertEqual(
            makeOutput(c: nil, g: s1, m: m1, p: m1.combineAnyAndAll().first ?? [], w: e1, t: s2),
            result.output.first,
            line: line
        )
        assertEqual(
            makeOutput(c: nil, g: s1, m: m2, p: m2.combineAnyAndAll().first ?? [], w: e1, t: s3),
            result.output.last,
            line: line
        )
    }
    
    func assertMatchClash(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        let sut = makeSUT(rest: [d1, d2])
        
        assertCount(sut.finalised().output, expected: 0, line: line)
    }
    
    func testInit() {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let rest = SVN(rest: [ARN(rest: [defineNode(s1, m1, e1, s2)])])
        
        assertEqualFileAndLine(rest, sut.rest.first!)
    }
    
    func testEmptyMatchOutput() {
        let sut = makeSUT(rest: [defineNode(s1, Match(), e1, s2)])
        let result = sut.finalised()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        assertEqual(makeOutput(c: nil, g: s1, m: Match(), p: [], w: e1, t: s2),
                    result.output.first)
    }
    
    func testPredicateMatchOutput() {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let result = sut.finalised()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 1)
        
        assertEqual(makeOutput(g: s1, m: m1, p: [P.a, Q.a], w: e1, t: s2),
                    result.output.first)
    }
    
    func testImplicitMatchClashes() {
        assertNotMatchClash(Match(), Match(all: P.a))
        // the issue seems to be the lack of distinction between if-if and if-else
        // there is no 'else' in this system, even though it is implied
        // Match(all: P.a); Match() means if P.a, ELSE...
        // Match(any: P.b, Q.b); Match(all: P.a) means if P.a or Q.b, if P.a
        // Builder arguments are if-else or if-if, or both/either?
        
        assertNotMatchClash(Match(all: P.a), Match(all: P.b))
        assertNotMatchClash(Match(all: P.a), Match(all: P.b, Q.b))
        assertNotMatchClash(Match(all: P.a, Q.a), Match(all: P.b, Q.b))
        
        assertMatchClash(Match(all: P.a), Match(all: Q.a))
        assertMatchClash(Match(all: P.a), Match(any: Q.a))
        
        assertMatchClash(Match(all: P.a, R.a), Match(all: Q.a, S.a))
        assertMatchClash(Match(any: P.a, R.a), Match(any: Q.a, S.a))
        
        assertMatchClash(Match(all: P.a), Match(all: Q.a, S.a))
        assertMatchClash(Match(all: P.a), Match(any: Q.a, S.a))
        
        assertMatchClash(Match(all: P.a), Match(any: P.b, Q.b))
        #warning("is it a clash? what does the eager system say?")
    }
}
