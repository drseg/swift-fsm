//
//  EagerMatchResolvingNodeTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

class EagerMatchResolvingNodeTests: DefineConsumer {
    struct ExpectedTableNodeOutput {
        let state: AnyHashable,
            match: Match,
            predicates: PredicateSet,
            event: AnyHashable,
            nextState: AnyHashable,
            actionsOutput: String
    }
    
    struct ExpectedTableNodeError {
        let state: AnyTraceable,
            match: Match,
            predicates: PredicateSet,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actionsOutput: String
    }
    
    typealias MRN = EagerMatchResolvingNode
    typealias SVN = SemanticValidationNode
    typealias Key = EagerMatchResolvingNode.ImplicitClashesKey
    typealias TableNodeResult = (output: [MRN.Output], errors: [Error])
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    enum R: Predicate { case a, b }
    
    func matchResolvingNode(rest: [any Node<DefineNode.Output>]) -> MRN {
        .init(rest: [SVN(rest: [ActionsResolvingNode(rest: rest)])])
    }
    
    func makeOutput(
        _ g: AnyTraceable,
        _ m: Match,
        _ p: [any Predicate],
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ a: String = "12"
    ) -> ExpectedTableNodeOutput {
        .init(state: g.base,
              match: m,
              predicates: Set(p.erased()),
              event: w.base,
              nextState: t.base,
              actionsOutput: a)
    }
    
    func makeErrorOutput(
        _ g: AnyTraceable,
        _ m: Match,
        _ p: [any Predicate],
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ a: String = "12"
    ) -> ExpectedTableNodeError {
        .init(state: g,
              match: m,
              predicates: Set(p.erased()),
              event: w,
              nextState: t,
              actionsOutput: a)
    }
    
    func assertResult(
        _ result: TableNodeResult,
        expected: ExpectedTableNodeOutput,
        line: UInt = #line
    ) {
        assertCount(result.errors, expected: 0, line: line)
        
        assertEqual(expected, result.output.first {
            $0.state == expected.state &&
            $0.predicates == expected.predicates &&
            $0.event == expected.event &&
            $0.nextState == expected.nextState
        }, line: line)
    }
    
    func assertError(
        _ result: TableNodeResult,
        expected: [ExpectedTableNodeError],
        line: UInt = #line
    ) {
        guard let clashError = result.errors[0] as? MRN.ImplicitClashesError else {
            XCTFail("unexpected error \(result.errors[0])", line: line)
            return
        }
        
        let clashes = clashError.clashes
        guard assertCount(clashes.first?.value, expected: expected.count, line: line) else {
            return
        }
        
        let errors = clashes.map(\.value).flattened
        
        expected.forEach { exp in
            assertEqual(exp, errors.first {
                $0.state == exp.state &&
                $0.match == exp.match &&
                $0.event == exp.event &&
                $0.nextState == exp.nextState
            }, line: line)
        }
    }
    
    func assertEqual(
        _ lhs: ExpectedTableNodeOutput?,
        _ rhs: MRN.Output?,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: line)
        XCTAssertEqual(lhs?.predicates, rhs?.predicates, line: line)
        XCTAssertEqual(lhs?.event, rhs?.event, line: line)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: line)
        
        assertActions(rhs?.actions, expectedOutput: lhs?.actionsOutput, line: line)
    }
    
    func assertEqual(
        _ lhs: ExpectedTableNodeError?,
        _ rhs: MRN.ErrorOutput?,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: line)
        XCTAssertEqual(lhs?.match, rhs?.match, line: line)
        XCTAssertEqual(lhs?.event, rhs?.event, line: line)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: line)
    }
    
    func testEmptyNode() {
        let result = matchResolvingNode(rest: []).finalised()
        
        assertCount(result.output, expected: 0)
        assertCount(result.errors, expected: 0)
    }
    
    func testTableWithNoMatches() {
        let d = defineNode(s1, Match(), e1, s2)
        let result = matchResolvingNode(rest: [d]).finalised()

        assertCount(result.output, expected: 1)
        assertResult(result, expected: makeOutput(s1, Match(), [], e1, s2))
    }
    
    func testMatchCondition() {
        let d = defineNode(s1, Match(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d]).finalised()
        
        XCTAssertEqual(false, result.output.first?.condition?())
    }
    
    func testImplicitMatch() {
        let d1 = defineNode(s1, Match(), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).finalised()
        
        assertCount(result.output, expected: 2)
        
        assertResult(result, expected: makeOutput(s1, Match(), [Q.b], e1, s2))
        assertResult(result, expected: makeOutput(s1, Match(any: Q.a), [Q.a], e1, s3))
    }
    
    func testImplicitMatchClash() {
        let d1 = defineNode(s1, Match(any: P.a), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).finalised()

        guard assertCount(result.errors, expected: 1) else { return }
        guard let clashError = result.errors[0] as? MRN.ImplicitClashesError else {
            XCTFail("unexpected error \(result.errors[0])"); return
        }
        
        guard assertCount(clashError.clashes.first?.value, expected: 2) else { return }
        assertError(result, expected: [makeErrorOutput(s1, Match(any: P.a), [P.a, Q.a], e1, s2),
                                       makeErrorOutput(s1, Match(any: Q.a), [P.a, Q.a], e1, s3)])
    }
    
    func testMoreSubtleImplicitMatchClashes() throws {
        let d1 = defineNode(s1, Match(any: P.a, R.a), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let d3 = defineNode(s1, Match(any: Q.a, S.a), e1, s1)
        
        let r1 = matchResolvingNode(rest: [d1, d2]).finalised()
        let r2 = matchResolvingNode(rest: [d1, d3]).finalised()
        
        XCTAssertFalse(r1.errors.isEmpty)
        XCTAssertFalse(r2.errors.isEmpty)
    }
    
    func testPassesConditionToOutput() {
        let d1 = defineNode(s1, Match(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d1]).finalised()
        
        guard assertCount(result.errors, expected: 0) else { return }
        guard assertCount(result.output, expected: 1) else { return }
        
        XCTAssertEqual(false, result.output.first?.condition?())
    }
}

