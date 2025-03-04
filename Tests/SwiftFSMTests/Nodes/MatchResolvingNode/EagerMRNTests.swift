import Testing
@testable import SwiftFSM

class EagerMatchResolvingNodeTests: MRNTestBase {
    struct ExpectedMRNError {
        let state: AnyTraceable,
            match: MatchDescriptorChain,
            predicates: PredicateSet,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actionsOutput: String
    }

    typealias Key = MatchResolvingNode.Eager.ImplicitClashesKey
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    enum R: Predicate { case a, b }
    
    func matchResolvingNode(rest: [any SyntaxNode<DefineNode.Output>]) -> EMRN {
        .init(rest: [SVN(rest: [ARN(rest: rest)])])
    }
    
    func makeErrorOutput(
        _ g: AnyTraceable,
        _ m: MatchDescriptorChain,
        _ p: [any Predicate],
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ a: String = "12"
    ) -> ExpectedMRNError {
        .init(state: g,
              match: m,
              predicates: Set(p.erased()),
              event: w,
              nextState: t,
              actionsOutput: a)
    }
    
    func assertError(
        _ result: MRNResult,
        expected: [ExpectedMRNError],
        location: SourceLocation = #_sourceLocation
    ) throws {
        let clashError = try #require(result.errors[0] as? EMRN.ImplicitClashesError)
        let clashes = clashError.clashes
        try #require(clashes.first?.value.count == expected.count, sourceLocation: location)
        
        let errors = clashes.map(\.value).flattened
        
        expected.forEach { exp in
            assertEqual(exp, errors.first {
                $0.state == exp.state &&
                $0.descriptor == exp.match &&
                $0.event == exp.event &&
                $0.nextState == exp.nextState
            }, location: location)
        }
    }
    
    func assertEqual(
        _ lhs: ExpectedMRNError?,
        _ rhs: EMRN.ErrorOutput?,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(lhs?.state == rhs?.state, sourceLocation: location)
        #expect(lhs?.match == rhs?.descriptor, sourceLocation: location)
        #expect(lhs?.event == rhs?.event, sourceLocation: location)
        #expect(lhs?.nextState == rhs?.nextState, sourceLocation: location)
    }
    
    @Test func emptyNode() throws {
        let result = matchResolvingNode(rest: []).resolve()
        
        try #require(result.output.count == 0)
        try #require(result.errors.count == 0)
    }
    
    @Test func tableWithNoMatches() async throws {
        let d = defineNode(s1, MatchDescriptorChain(), e1, s2)
        let result = matchResolvingNode(rest: [d]).resolve()
        
        try #require(result.output.count == 1)
        try await assertResult(
            result,
            expected: makeOutput(
                c: nil,
                g: s1,
                m: MatchDescriptorChain(),
                p: [],
                w: e1,
                t: s2
            )
        )
    }
    
    @Test func matchCondition() async {
        let d = defineNode(s1, MatchDescriptorChain(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d]).resolve()
        let condition = result.output.first?.condition?()
        
        #expect(condition == false)
    }
    
    @Test func implicitMatch() async throws {
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).resolve()
        
        try #require(result.output.count == 2)
        
        try await assertResult(
            result,
            expected: makeOutput(
                c: nil,
                g: s1,
                m: MatchDescriptorChain(),
                p: [Q.b],
                w: e1,
                t: s2
            )
        )
        
        try await assertResult(
            result, expected: makeOutput(
                c: nil,
                g: s1,
                m: MatchDescriptorChain(any: Q.a),
                p: [Q.a],
                w: e1,
                t: s3
            )
        )
    }
    
    @Test func implicitMatchClash() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(any: P.a), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).resolve()
        
        try #require(result.errors.count == 1)
        let clashError = try #require(result.errors[0] as? EMRN.ImplicitClashesError)
        try #require(clashError.clashes.first?.value.count == 2)
        try assertError(
            result,
            expected: [makeErrorOutput(s1, MatchDescriptorChain(any: P.a), [P.a, Q.a], e1, s2),
                       makeErrorOutput(s1, MatchDescriptorChain(any: Q.a), [P.a, Q.a], e1, s3)])
    }
    
    @Test func moreSubtleImplicitMatchClashes() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(any: P.a, R.a), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let d3 = defineNode(s1, MatchDescriptorChain(any: Q.a, S.a), e1, s1)
        
        let r1 = matchResolvingNode(rest: [d1, d2]).resolve()
        let r2 = matchResolvingNode(rest: [d1, d3]).resolve()
        
        #expect(!r1.errors.isEmpty)
        #expect(!r2.errors.isEmpty)
    }
    
    @Test func passesConditionToOutput() async throws {
        let d1 = defineNode(s1, MatchDescriptorChain(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d1]).resolve()
        
        try #require(result.errors.count == 0)
        try #require(result.output.count == 1)
        
        let condition = result.output.first?.condition?()
        #expect(condition == false)
    }
}

