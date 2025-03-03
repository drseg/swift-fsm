import Testing
@testable import SwiftFSM

class MRNTestBase: StringableNodeTest {
    typealias ARN = ActionsResolvingNode.OnStateChange
    typealias EMRN = MatchResolvingNode.Eager
    typealias SVN = SemanticValidationNode
    typealias MRNResult = (output: [Transition], errors: [Error])
    
    struct ExpectedMRNOutput {
        let condition: Bool?,
            state: AnyHashable,
            match: MatchDescriptorChain,
            predicates: PredicateSet,
            event: AnyHashable,
            nextState: AnyHashable,
            actionsOutput: String
        
        init(
            condition: Bool? = false,
            state: AnyHashable,
            match: MatchDescriptorChain,
            predicates: PredicateSet,
            event: AnyHashable,
            nextState: AnyHashable,
            actionsOutput: String
        ) {
            self.condition = condition
            self.state = state
            self.match = match
            self.predicates = predicates
            self.event = event
            self.nextState = nextState
            self.actionsOutput = actionsOutput
        }
    }
    
    func makeOutput(
        c: Bool? = false,
        g: AnyTraceable,
        m: MatchDescriptorChain,
        p: [any Predicate],
        w: AnyTraceable,
        t: AnyTraceable,
        a: String = "12"
    ) -> ExpectedMRNOutput {
        .init(condition: c,
              state: g.base,
              match: m,
              predicates: Set(p.erased()),
              event: w.base,
              nextState: t.base,
              actionsOutput: a)
    }
    
    func makeOutput(
        c: Bool? = false,
        g: AnyTraceable,
        m: MatchDescriptorChain,
        p: Set<AnyPredicate>,
        w: AnyTraceable,
        t: AnyTraceable,
        a: String = "12"
    ) -> ExpectedMRNOutput {
        .init(condition: c,
              state: g.base,
              match: m,
              predicates: p,
              event: w.base,
              nextState: t.base,
              actionsOutput: a)
    }
    
    func assertResult(
        _ result: MRNResult,
        expected: ExpectedMRNOutput,
        location: SourceLocation = #_sourceLocation
    ) async throws {
        try #require(result.errors.isEmpty, sourceLocation: location)
        
        await assertEqual(expected, result.output.first {
            $0.state == expected.state &&
            $0.predicates == expected.predicates &&
            $0.event == expected.event &&
            $0.nextState == expected.nextState
        }, location: location)
    }
    
    func assertEqual(
        _ lhs: ExpectedMRNOutput?,
        _ rhs: Transition?,
        location: SourceLocation = #_sourceLocation
    ) async {
        let condition = rhs?.condition?()
        #expect(lhs?.condition == condition, sourceLocation: location)
        #expect(lhs?.state == rhs?.state, sourceLocation: location)
        #expect(lhs?.predicates == rhs?.predicates, sourceLocation: location)
        #expect(lhs?.event == rhs?.event, sourceLocation: location)
        #expect(lhs?.nextState == rhs?.nextState, sourceLocation: location)
        
        await assertActions(
            rhs?.actions,
            expectedOutput: lhs?.actionsOutput,
            location: location
        )
    }
}
