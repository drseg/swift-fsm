import Testing
@testable import SwiftFSM

class LazyMatchResolvingNodeTests: MRNTestBase {
    typealias LMRN = MatchResolvingNode.Lazy
    
    func makeSUT(rest: [any SyntaxNode<DefineNode.Output>]) -> LMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    func assertNotMatchClash(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        location: SourceLocation = #_sourceLocation
    ) async throws {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        
        let p1 = m1.resolvedPredicates().first ?? []
        let p2 = m2.resolvedPredicates().first ?? []
        
        let result = makeSUT(rest: [d1, d2]).resolve()
        
        try #require(result.errors.count == 0)
        try #require(result.output.count == 2)
        
        await assertEqual(
            makeOutput(c: nil, g: s1, m: m1, p: p1, w: e1, t: s2),
            result.output.first,
            location: location
        )
        
        await assertEqual(
            makeOutput(c: nil, g: s1, m: m2, p: p2, w: e1, t: s3),
            result.output.last,
            location: location
        )
    }
    
    func assertMatchClash(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        location: SourceLocation = #_sourceLocation
    ) throws {
        let d1 = defineNode(s1, m1, e1, s2)
        let d2 = defineNode(s1, m2, e1, s3)
        let result = makeSUT(rest: [d1, d2]).resolve()
        
        try #require(result.errors.count == 1)
        try #require(result.output.count == 0)
        
        #expect(result.errors.first is EMRN.ImplicitClashesError, sourceLocation: location)
    }
    
    @Test func canInit() async {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let rest = SVN(rest: [ARN(rest: [defineNode(s1, m1, e1, s2)])])
        await assertEqualFileAndLine(rest, sut.rest.first!)
    }
    
    @Test func emptyMatchOutput() async throws {
        let sut = makeSUT(rest: [defineNode(s1, MatchDescriptorChain(), e1, s2)])
        let result = sut.resolve()
        
        try #require(result.errors.count == 0)
        try #require(result.output.count == 1)
        
        await assertEqual(
            makeOutput(
                c: nil, g: s1, m: MatchDescriptorChain(), p: [], w: e1, t: s2
            ),
            result.output.first
        )
    }

    @Test func predicateMatchOutput() async throws {
        let sut = makeSUT(rest: [defineNode(s1, m1, e1, s2)])
        let result = sut.resolve()
        
        try #require(result.errors.count == 0)
        try #require(result.output.count == 1)
        
        await assertEqual(
            makeOutput(
                g: s1, m: m1, p: [P.a, Q.a], w: e1, t: s2
            ),
            result.output.first
        )
    }
    
    @Test func implicitMatchClashes() async throws {
        try await assertNotMatchClash(MatchDescriptorChain(), MatchDescriptorChain(all: P.a))
        try await assertNotMatchClash(MatchDescriptorChain(), MatchDescriptorChain(all: P.a, Q.a))
        try await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: Q.a, S.a))
        
        try await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: P.b))
        try await assertNotMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: P.b, Q.b))
        try await assertNotMatchClash(MatchDescriptorChain(all: P.a, Q.a), MatchDescriptorChain(all: P.b, Q.b))
        
        try assertMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(all: Q.a))
        try assertMatchClash(MatchDescriptorChain(all: P.a), MatchDescriptorChain(any: Q.a))
        try assertMatchClash(MatchDescriptorChain(all: P.a, R.a), MatchDescriptorChain(all: Q.a, S.a))
    }
}
