import XCTest
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

    typealias Key = EagerMatchResolvingNode.ImplicitClashesKey
    
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
        line: UInt = #line
    ) {
        guard let clashError = result.errors[0] as? EMRN.ImplicitClashesError else {
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
                $0.descriptor == exp.match &&
                $0.event == exp.event &&
                $0.nextState == exp.nextState
            }, line: line)
        }
    }
    
    func assertEqual(
        _ lhs: ExpectedMRNError?,
        _ rhs: EMRN.ErrorOutput?,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: line)
        XCTAssertEqual(lhs?.match, rhs?.descriptor, line: line)
        XCTAssertEqual(lhs?.event, rhs?.event, line: line)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: line)
    }
    
    func testEmptyNode() {
        let result = matchResolvingNode(rest: []).resolve()
        
        assertCount(result.output, expected: 0)
        assertCount(result.errors, expected: 0)
    }
    
    func testTableWithNoMatches() async {
        let d = defineNode(s1, MatchDescriptorChain(), e1, s2)
        let result = matchResolvingNode(rest: [d]).resolve()
        
        assertCount(result.output, expected: 1)
        await assertResult(
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
    
    func testMatchCondition() async {
        let d = defineNode(s1, MatchDescriptorChain(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d]).resolve()
        let condition = result.output.first?.condition?()
        
        XCTAssertEqual(false, condition)
    }
    
    func testImplicitMatch() async {
        let d1 = defineNode(s1, MatchDescriptorChain(), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).resolve()
        
        assertCount(result.output, expected: 2)
        
        await assertResult(
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
        
        await assertResult(
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
    
    func testImplicitMatchClash() {
        let d1 = defineNode(s1, MatchDescriptorChain(any: P.a), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let result = matchResolvingNode(rest: [d1, d2]).resolve()

        guard assertCount(result.errors, expected: 1) else { return }
        guard let clashError = result.errors[0] as? EMRN.ImplicitClashesError else {
            XCTFail("unexpected error \(result.errors[0])"); return
        }
        
        guard assertCount(clashError.clashes.first?.value, expected: 2) else { return }
        assertError(result, expected: [makeErrorOutput(s1, MatchDescriptorChain(any: P.a), [P.a, Q.a], e1, s2),
                                       makeErrorOutput(s1, MatchDescriptorChain(any: Q.a), [P.a, Q.a], e1, s3)])
    }
    
    func testMoreSubtleImplicitMatchClashes() throws {
        let d1 = defineNode(s1, MatchDescriptorChain(any: P.a, R.a), e1, s2)
        let d2 = defineNode(s1, MatchDescriptorChain(any: Q.a), e1, s3)
        let d3 = defineNode(s1, MatchDescriptorChain(any: Q.a, S.a), e1, s1)
        
        let r1 = matchResolvingNode(rest: [d1, d2]).resolve()
        let r2 = matchResolvingNode(rest: [d1, d3]).resolve()
        
        XCTAssertFalse(r1.errors.isEmpty)
        XCTAssertFalse(r2.errors.isEmpty)
    }
    
    func testPassesConditionToOutput() async {
        let d1 = defineNode(s1, MatchDescriptorChain(condition: { false }), e1, s2)
        let result = matchResolvingNode(rest: [d1]).resolve()
        
        guard assertCount(result.errors, expected: 0) else { return }
        guard assertCount(result.output, expected: 1) else { return }
        
        let condition = result.output.first?.condition?()
        XCTAssertEqual(false, condition)
    }
}

