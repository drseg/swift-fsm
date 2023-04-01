//
//  TableNodeTests.swift
//
//  Created by Daniel Segall on 20/03/2023.
//

import XCTest
@testable import SwiftFSM

class MatchResolvingNodeTests: DefineConsumer {
    typealias ExpectedTableNodeOutput = (state: AnyTraceable,
                                         match: Match,
                                         predicates: PredicateSet,
                                         event: AnyTraceable,
                                         nextState: AnyTraceable,
                                         actionsOutput: String)
    
    typealias PTN = MatchResolvingNode
    typealias SVN = SemanticValidationNode
    typealias Key = MatchResolvingNode.ImplicitClashesKey
    typealias TableNodeResult = (output: [PTN.Output], errors: [Error])
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    
    func tableNode(rest: [any Node<DefineNode.Output>]) -> PTN {
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
        (state: g, match: m, predicates: Set(p.erased()), event: w, nextState: t, actionsOutput: a)
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
        expected: [ExpectedTableNodeOutput],
        line: UInt = #line
    ) {
        guard let clashError = result.errors[0] as? PTN.ImplicitClashesError else {
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
                $0.predicates == exp.predicates &&
                $0.event == exp.event &&
                $0.nextState == exp.nextState
            }, line: line)
        }
    }
    
    func assertEqual(
        _ lhs: ExpectedTableNodeOutput?,
        _ rhs: PTN.Output?,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: line)
        XCTAssertEqual(lhs?.predicates, rhs?.predicates, line: line)
        XCTAssertEqual(lhs?.event, rhs?.event, line: line)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: line)
        
        assertActions(rhs?.actions, expectedOutput: lhs?.actionsOutput, line: line)
    }
    
    func testEmptyNode() {
        let result = tableNode(rest: []).finalised()
        
        assertCount(result.output, expected: 0)
        assertCount(result.errors, expected: 0)
    }
    
    func testTableWithNoMatches() {
        let d1 = defineNode(s1, Match(), e1, s2)
        let result = tableNode(rest: [d1]).finalised()

        assertCount(result.output, expected: 1)
        assertResult(result, expected: makeOutput(s1, Match(), [], e1, s2))
    }
    
    func testImplicitMatch() {
        let d1 = defineNode(s1, Match(), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let result = tableNode(rest: [d1, d2]).finalised()
        
        assertCount(result.output, expected: 2)
        
        assertResult(result, expected: makeOutput(s1, Match(), [Q.b], e1, s2))
        assertResult(result, expected: makeOutput(s1, Match(any: Q.a), [Q.a], e1, s3))
    }
    
    func testImplicitMatchClash() {
        let d1 = defineNode(s1, Match(any: P.a), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let result = tableNode(rest: [d1, d2]).finalised()

        guard assertCount(result.errors, expected: 1) else { return }
        guard let clashError = result.errors[0] as? PTN.ImplicitClashesError else {
            XCTFail("unexpected error \(result.errors[0])"); return
        }
        
        let clashes = clashError.clashes
        guard assertCount(clashes.first?.value, expected: 2) else { return }
        
        assertError(result, expected: [makeOutput(s1, Match(any: P.a), [P.a, Q.a], e1, s2),
                                       makeOutput(s1, Match(any: Q.a), [P.a, Q.a], e1, s3)])
    }
}

