import XCTest
@testable import SwiftFSM

class MRNTestBase: StringableNodeTest {
    typealias ARN = ActionsResolvingNode
    typealias EMRN = EagerMatchResolvingNode
    typealias SVN = SemanticValidationNode
    typealias MRNResult = (output: [Transition], errors: [Error])
    
    struct ExpectedMRNOutput {
        let condition: Bool?,
            state: AnyHashable,
            match: Match,
            predicates: PredicateSet,
            event: AnyHashable,
            nextState: AnyHashable,
            actionsOutput: String
        
        init(
            condition: Bool? = false,
            state: AnyHashable,
            match: Match,
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
        m: Match,
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
    
    func assertResult(
        _ result: MRNResult,
        expected: ExpectedMRNOutput,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertCount(result.errors, expected: 0, file: file, line: line)
        
        assertEqual(expected, result.output.first {
            $0.state == expected.state &&
            $0.predicates == expected.predicates &&
            $0.event == expected.event &&
            $0.nextState == expected.nextState
        }, file: file, line: line)
    }
    
    func assertEqual(
        _ lhs: ExpectedMRNOutput?,
        _ rhs: Transition?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.condition, rhs?.condition?(), file: file, line: line)
        XCTAssertEqual(lhs?.state, rhs?.state, file: file, line: line)
        XCTAssertEqual(lhs?.predicates, rhs?.predicates, file: file, line: line)
        XCTAssertEqual(lhs?.event, rhs?.event, file: file, line: line)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, file: file, line: line)
        
        assertActions(rhs?.actions, expectedOutput: lhs?.actionsOutput, file: file, line: line)
    }
}
