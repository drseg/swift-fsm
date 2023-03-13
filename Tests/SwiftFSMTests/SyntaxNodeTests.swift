//
//  SwiftFSMTests.swift
//  
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
import Algorithms
@testable import SwiftFSM

class SyntaxNodeTests: XCTestCase {
    let s1: AnyTraceable = "S1", s2: AnyTraceable = "S2", s3: AnyTraceable = "S3"
    let e1: AnyTraceable = "E1", e2: AnyTraceable = "E2", e3: AnyTraceable = "E3"
    
    var actionsOutput = ""
    
    var actions: [Action] {
        [{ self.actionsOutput += "1" },
         { self.actionsOutput += "2" }]
    }
    
    var entryActions: [Action] {
        [{ self.actionsOutput += "<" },
         { self.actionsOutput += "<" }]
    }
    
    var exitActions: [Action] {
        [{ self.actionsOutput += ">" },
         { self.actionsOutput += ">" }]
    }
    
    var actionsNode: ActionsNode {
        ActionsNode(actions: actions)
    }
    
    var thenNode: ThenNode {
        ThenNode(state: s1,
                 rest: [actionsNode])
    }
    
    var whenNode: WhenNode {
        WhenNode(events: [e1, e2],
                 rest: [thenNode])
    }
    
    var m1: Match {
        Match(any: P.a, all: Q.a)
    }
    
    func givenNode(thenState: AnyTraceable?, actionsNode: ActionsNode) -> GivenNode {
        let t = ThenNode(state: thenState, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w])
        
        return GivenNode(states: [s1, s2], rest: [m])
    }
    
    func assertEqual(
        _ lhs: DefaultIO,
        _ rhs: DefaultIO,
        line: UInt = #line
    ) {
        XCTAssertTrue(lhs.match == rhs.match &&
                      lhs.event == rhs.event &&
                      lhs.state == rhs.state,
                      "\(lhs) does not equal \(rhs)",
                      line: line)
    }
    
    func assertEqual(lhs: [MSES], rhs: [MSES], line: UInt) {
        XCTAssertTrue(isEqual(lhs: lhs, rhs: rhs),
    """
    \n\nActual: \(lhs.description)
    
    did not equal expected: \(rhs.description)
    """,
                      line: line)
    }
    
    
    func isEqual(lhs: [MSES], rhs: [MSES]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (lhs, rhs) in zip(lhs, rhs) {
            guard lhs.match.finalise() == rhs.match.finalise() &&
                    lhs.state == rhs.state &&
                    lhs.event == rhs.event &&
                    lhs.nextState == rhs.nextState else { return false }
        }
        return true
    }
    
    func randomisedTrace(_ base: String) -> AnyTraceable {
        AnyTraceable(base: base,
                     file: UUID().uuidString,
                     line: Int.random(in: 0...Int.max))
    }
    
    func assertEmptyThen(
        _ t: ThenNode,
        thenState: AnyTraceable? = "S1",
        line: UInt = #line
    ) {
        let finalised = t.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        guard assertCount(actual: result.count, expected: 1, line: line) else {
            return
        }
        
        XCTAssertTrue(errors.isEmpty, line: line)
        XCTAssertEqual(thenState, result[0].state, line: line)
        XCTAssertTrue(result[0].actions.isEmpty, line: line)
    }
    
    func assertThenWithActions(
        expected: String,
        _ t: ThenNode,
        line: UInt = #line
    ) {
        let finalised = t.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(errors.isEmpty, line: line)
        XCTAssertEqual(result[0].state, s1, line: line)
        result.executeAll()
        XCTAssertEqual(expected, actionsOutput, line: line)
    }
    
    func assertEmptyNodeWithoutError(_ n: some Node, line: UInt = #line) {
        let f = n.finalised()
        
        XCTAssertTrue(f.output.isEmpty, "Output not empty: \(f.0)", line: line)
        XCTAssertTrue(f.errors.isEmpty, "Errors not empty: \(f.1)", line: line)
    }
    
    func assertEmptyNodeWithError(_ n: some NeverEmptyNode, line: UInt = #line) {
        XCTAssertEqual(n.finalised().errors as? [EmptyBuilderError],
                       [EmptyBuilderError(caller: n.caller,
                                          file: n.file,
                                          line: n.line)],
                       line: line)
    }
    
    func assertWhen(
        state: AnyTraceable?,
        actionsCount: Int,
        actionsOutput: String,
        node: WhenNode,
        line: UInt
    ) {
        let result = node.finalised().0
        let errors = node.finalised().1
        
        (0..<2).forEach {
            XCTAssertEqual(state, result[$0].state, line: line)
            XCTAssertEqual(actionsCount, result[$0].actions.count, line: line)
            result.executeAll()
        }
        
        XCTAssertEqual(e1, result[0].event, line: line)
        XCTAssertEqual(e2, result[1].event, line: line)
        
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
        XCTAssertTrue(errors.isEmpty, line: line)
    }
    
    func assertCount(actual: Int, expected: Int, line: UInt = #line) -> Bool {
        guard actual == expected else {
            XCTFail("Incorrect count: \(actual) instead of \(expected)",
                    line: line)
            return false
        }
        return true
    }
    
    func assertMatch(_ m: MatchNode, line: UInt = #line) {
        let finalised = m.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(errors.isEmpty, line: line)
        XCTAssertEqual(result.count, 2, line: line)
        
        assertEqual(result[0], (Match(), e1, s1, []), line: line)
        assertEqual(result[1], (Match(), e2, s1, []), line: line)
        
        result.executeAll()
        XCTAssertEqual(actionsOutput, "1212", line: line)
    }
    
    func assertGivenNode(
        expected: [MSES],
        actionsOutput: String,
        node: GivenNode,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { ($0.match, $0.state, $0.event, $0.nextState) },
                    line: line)
        
        result.map(\.actions).flattened.executeAll()
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
        XCTAssertTrue(errors.isEmpty, line: line)
    }
    
    func assertDefineNode(
        expected: [MSES],
        actionsOutput: String,
        node: DefineNode,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { ($0.match, $0.state, $0.event, $0.nextState) },
                    line: line)
        
        result.forEach {
            $0.entryActions.executeAll()
            $0.actions.executeAll()
            $0.exitActions.executeAll()
        }
        
        XCTAssertTrue(errors.isEmpty, line: line)
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
    
    func assertDefaultIONodeChains(
        node: any DefaultIONode,
        match: Match = Match(any: P.a, all: Q.a),
        event: AnyTraceable = "E1",
        state: AnyTraceable = "S1",
        actionsOutput: String = "chain",
        line: UInt = #line
    ) {
        let nodeChains: [any Node<DefaultIO>] = {
            let nodes: [any DefaultIONode] =
            [MatchNode(match: Match(any: P.a, all: Q.a)),
             WhenNode(events: [e1]),
             ThenNode(state: s1),
             ActionsNode(actions: [{ self.actionsOutput += "chain" }])]
                        
            return nodes.permutations(ofCount: 4).map { $0 }.reduce(into: [any Node<DefaultIO>]()) {
                var one = $1[0].copy(),
                    two = $1[1].copy(),
                    three = $1[2].copy(),
                    four = $1[3].copy()
                
                three.rest.append(four as! any Node<DefaultIO>)
                two.rest.append(three as! any Node<DefaultIO>)
                one.rest.append(two as! any Node<DefaultIO>)
                
                $0.append(one as! any Node<DefaultIO>)
            }
        }()
        
        nodeChains.forEach {
            var node = node.copy()
            node.rest.append($0)
            
            let output = node.finalised()
            let results = output.0
                        
            guard assertCount(actual: results.count, expected: 1, line: line) else {
                return
            }
            
            let result = results[0]
            
            let actualPredicates = result.match.finalise()
            let expectedPredicates = match.finalise()
            
            XCTAssertEqual(expectedPredicates, actualPredicates, line: line)
            XCTAssertEqual(event, result.event, line: line)
            XCTAssertEqual(state, result.state, line: line)
            
            result.actions.executeAll()
            XCTAssertEqual(actionsOutput, self.actionsOutput, line: line)
            
            self.actionsOutput = ""
        }
    }
}

final class TraceableTests: SyntaxNodeTests {
    func testTraceableEquality() {
        let t1 = randomisedTrace("cat")
        let t2 = randomisedTrace("cat")
        let t3 = randomisedTrace("bat")
        let t4: AnyTraceable = "cat"
        
        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1, t4)
        XCTAssertNotEqual(t1, t3)
    }
    
    func testTraceableHashing() {
        var randomCat: AnyTraceable { randomisedTrace("cat") }
        
        1000 * {
            let dict = [randomCat: randomCat]
            XCTAssertEqual(dict[randomCat], randomCat)
        }
    }
    
    func testTraceableDescription() {
        XCTAssertEqual(s1.description, "S1")
    }
}

final class ErrorTests: SyntaxNodeTests {
    func testEmptyBlockError() {
        let error = EmptyBuilderError(file: "file", line: 10)
        
        XCTAssertEqual("testEmptyBlockError", error.caller)
        XCTAssertEqual(10, error.line)
        XCTAssertEqual("file", error.file)
    }
}

final class ActionsNodeTests: SyntaxNodeTests {
    func testEmptyActions() {
        assertEmptyNodeWithoutError(ActionsNode(actions: [], rest: []))
    }
    
    func testEmptyActionsBlock() {
        assertEmptyNodeWithError(ActionsBlockNode(actions: [], rest: []))
    }
    
    func testActionsFinalisesCorrectly() {
        let n = actionsNode
        n.finalised().output.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.finalised().errors.isEmpty)
    }
    
    func testActionsPlusChainFinalisesCorrectly() {
        let a = ActionsNode(actions: [{ self.actionsOutput += "action" }])
        assertDefaultIONodeChains(node: a, actionsOutput: "actionchain")
    }
}

final class ThenNodeTests: SyntaxNodeTests {
    func testNilThenNodeState() {
        assertEmptyThen(
            ThenNode(state: nil, rest: []),
            thenState: nil
        )
    }
    
    func testEmptyThenNode() {
        assertEmptyThen(
            ThenNode(state: s1, rest: [])
        )
    }
    
    func testThenNodeWithEmptyRest() {
        assertEmptyThen(
            ThenNode(state: s1,
                     rest: [ActionsNode(actions: [])])
        )
    }
    
    func testEmptyThenBlockNode() {
        assertEmptyNodeWithError(ThenBlockNode(state: s1, rest: []))
    }
    
    func testThenNodeFinalisesCorrectly() {
        assertThenWithActions(
            expected: "12",
            ThenNode(state: s1, rest: [actionsNode])
        )
    }
    
    func testThenNodePlusChainFinalisesCorrectly() {
        let t = ThenNode(state: s2)
        assertDefaultIONodeChains(node: t, state: s2)
    }
    
    func testThenNodeCanSetRestAfterInit() {
        let t = ThenNode(state: s1)
        t.rest.append(actionsNode)
        assertThenWithActions(expected: "12", t)
    }
    
    func testThenNodeFinalisesWithMultipleActionsNodes() {
        assertThenWithActions(
            expected: "1212",
            ThenNode(state: s1, rest: [actionsNode,
                                       actionsNode])
        )
    }
}

final class WhenNodeTests: SyntaxNodeTests {
    func testEmptyWhenNode() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: []))
    }
    
    func testEmptyWhenNodeWithActions() {
        assertEmptyNodeWithError(WhenNode(events: [], rest: [thenNode]))
    }
    
    func testEmptyWhenBlockNodeWithActions() {
        assertEmptyNodeWithError(WhenBlockNode(events: [e1]))
    }
    
    func testWhenNodeWithEmptyRest() {
        assertWhen(state: nil,
                   actionsCount: 0,
                   actionsOutput: "",
                   node: WhenNode(events: [e1, e2], rest: []),
                   line: #line)
    }
    
    func assertWhenNodeWithActions(
        expected: String = "1212",
        _ w: WhenNode,
        line: UInt = #line
    ) {
        assertWhen(state: s1,
                   actionsCount: 2,
                   actionsOutput: expected,
                   node: w,
                   line: line)
    }
    
    func testWhenNodeFinalisesCorrectly() {
        assertWhenNodeWithActions(
            WhenNode(events: [e1, e2], rest: [thenNode])
        )
    }
    
    func testWhenNodeWithChainFinalisesCorrectly() {
        let w = WhenNode(events: [e3])
        assertDefaultIONodeChains(node: w, event: e3)
    }
    
    func testWhenNodeCanSetRestAfterInit() {
        let w = WhenNode(events: [e1, e2])
        w.rest.append(thenNode)
        assertWhenNodeWithActions(w)
    }
}

final class MatchNodeTests: SyntaxNodeTests {
    func testEmptyMatchNodeIsNotError() {
        XCTAssertEqual(0, MatchNode(match: Match(), rest: []).finalised().errors.count)
    }
    
    func testEmptyMatchBlockNodeIsError() {
        assertEmptyNodeWithError(MatchBlockNode(match: Match(), rest: []))
    }
    
    func testMatchNodeFinalisesCorrectly() {
        assertMatch(MatchNode(match: Match(), rest: [whenNode]))
    }
    
    func testMatchNodeWithChainFinalisesCorrectly() {
        let m = MatchNode(match: Match(any: P.b, all: R.a))
        assertDefaultIONodeChains(node: m, match: Match(any: P.a, P.b,
                                                        all: Q.a, R.a))
    }
    
    func testMatchNodeCanSetRestAfterInit() {
        let m = MatchNode(match: Match())
        m.rest.append(whenNode)
        assertMatch(m)
    }
}

final class GivenNodeTests: SyntaxNodeTests {
    func testEmptyGivenNode() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: []))
    }
    
    func testGivenNodeWithEmptyStates() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: [whenNode]))
    }
    
    func testGivenNodeWithEmptyRest() {
        assertEmptyNodeWithoutError(GivenNode(states: [s1, s2], rest: []))
    }

    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let expected = [(m1, s1, e1, s1),
                        (m1, s1, e2, s1),
                        (m1, s2, e1, s2),
                        (m1, s2, e2, s2)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: givenNode(thenState: nil,
                                        actionsNode: actionsNode))
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: givenNode(thenState: s3,
                                        actionsNode: actionsNode))
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w])
        var g = GivenNode(states: [s1, s2])
        g.rest.append(m)
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: g)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = ThenNode(state: s3, rest: [actionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w, w])
        let g = GivenNode(states: [s1, s2], rest: [m])
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "1212121212121212",
                        node: g)
    }
}

final class DefineNodeTests: SyntaxNodeTests {
    func testEmptyDefineNodeProducesError() {
        assertEmptyNodeWithError(
            DefineNode(
                entryActions: [],
                exitActions: [],
                rest: [],
                caller: "caller",
                file: "file",
                line: 10
            )
        )
    }
    
    func testDefineNodeWithActionsButNoRestProducesError() {
        assertEmptyNodeWithError(
            DefineNode(
                entryActions: [{ }],
                exitActions: [{ }],
                rest: [],
                caller: "caller",
                file: "file",
                line: 10
            )
        )
    }
    
    func testCompleteMatchNodeWithInvalidMatchProducesError() {
        let invalidMatch = Match(all: P.a, P.a)
        
        let m = MatchNode(match: invalidMatch, rest: [WhenNode(events: [e1])])
        let g = GivenNode(states: [s1], rest: [m])
        let d = DefineNode(entryActions: [], exitActions: [], rest: [g])
        
        let result = d.finalised()
        
        XCTAssertEqual(1, result.errors.count)
        XCTAssertTrue(result.errors.first is MatchError)
    }
    
    func testDefineNodeWithNoActions() {
        let d = DefineNode(entryActions: [],
                           exitActions: [],
                           rest: [givenNode(thenState: s3,
                                            actionsNode: ActionsNode(actions: []))])
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeCanSetRestAfterInit() {
        let t = ThenNode(state: s3, rest: [])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let m = MatchNode(match: m1, rest: [w])
        let g = GivenNode(states: [s1, s2], rest: [m])
        
        let d = DefineNode(entryActions: [],
                           exitActions: [])
        d.rest.append(g)
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeWithMultipleGivensWithEntryActionsAndExitActions() {
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [givenNode(thenState: s3,
                                            actionsNode: actionsNode),
                                  givenNode(thenState: s3,
                                            actionsNode: actionsNode)])
        
        let expected = [(m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3),
                        (m1, s1, e1, s3),
                        (m1, s1, e2, s3),
                        (m1, s2, e1, s3),
                        (m1, s2, e2, s3)]
        
        assertDefineNode(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    func testDefineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() {
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [givenNode(thenState: nil,
                                            actionsNode: actionsNode)])
        
        let expected = [(m1, s1, e1, s1),
                        (m1, s1, e2, s1),
                        (m1, s2, e1, s2),
                        (m1, s2, e2, s2)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
}

final class TableNodeTests: SyntaxNodeTests {
    // PreemptiveTableNode
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    
    typealias ExpectedTableNodeOutput = (state: AnyTraceable,
                                         predicates: PredicateResult,
                                         event: AnyTraceable,
                                         nextState: AnyTraceable,
                                         actionsOutput: String,
                                         entryActionsOutput: String,
                                         exitActionsOutput: String)
    
    func assertEqual(
        _ lhs: ExpectedTableNodeOutput?,
        _ rhs: TableNodeOutput?,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: xl)
        XCTAssertEqual(lhs?.predicates, rhs?.predicates, line: xl)
        XCTAssertEqual(lhs?.event, rhs?.event, line: xl)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: xl)
        
        rhs?.actions.executeAll()
        XCTAssertEqual(lhs?.actionsOutput, actionsOutput, line: xl)
        actionsOutput = ""
        
        rhs?.entryActions.executeAll()
        XCTAssertEqual(lhs?.entryActionsOutput, actionsOutput, line: xl)
        actionsOutput = ""
        
        rhs?.exitActions.executeAll()
        XCTAssertEqual(lhs?.exitActionsOutput, actionsOutput, line: xl)
        actionsOutput = ""
    }
    
    func makeOutput(
        state: AnyTraceable,
        predicates: PredicateResult,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actionsOutput: String = "12",
        entryActionsOutput: String = "<<",
        exitActionsOutput: String = ">>"
    ) -> ExpectedTableNodeOutput {
        (state: state,
         predicates: predicates,
         event: event,
         nextState: nextState,
         actionsOutput: actionsOutput,
         entryActionsOutput: entryActionsOutput,
         exitActionsOutput: exitActionsOutput)
    }
    
    func assertDupe(
        _ dupe: PreemptiveTableNode.PossibleError?,
        expected: PreemptiveTableNode.PossibleError?,
        xctLine xl: UInt = #line
    ) {
        let message = "\(String(describing: dupe)) does not equal \(String(describing: expected))"
        
        guard let dupe, let expected else { XCTFail(message); return }
        
        XCTAssertTrue(expected == dupe, message, line: xl)
    }
    
    typealias TableNodeResult = (output: [PreemptiveTableNode.Output], errors: [Error])
    
    func firstDuplicatesError(in result: TableNodeResult) -> DuplicatesError? {
        firstError(ofType: DuplicatesError.self, in: result)
    }
    
    func firstLogicalClashError(in result: TableNodeResult) -> LogicalClashError? {
        firstError(ofType: LogicalClashError.self, in: result)
    }
    
    func firstError<T>(ofType t: T.Type, in result: TableNodeResult) -> T? {
        result.1.first(where: { $0 is T }) as? T
    }
    
    func errorAssertionFailure(in result: TableNodeResult, xctLine xl: UInt = #line) {
        XCTFail("Unexpected error \(String(describing: result.1.first))", line: xl)
    }
    
    func tableNode(
        given: AnyTraceable,
        match: Match,
        when: AnyTraceable,
        then: AnyTraceable
    ) -> PreemptiveTableNode {
        .init(rest: [defineNode(given: given, match: match, when: when, then: then)])
    }
    
    func defineNode(
        given: AnyTraceable,
        match: Match,
        when: AnyTraceable,
        then: AnyTraceable
    ) -> DefineNode {
        let actions = ActionsNode(actions: actions)
        let then = ThenNode(state: then, rest: [actions])
        let when = WhenNode(events: [when], rest: [then])
        let match = MatchNode(match: match, rest: [when])
        let given = GivenNode(states: [given], rest: [match])
        return .init(entryActions: entryActions, exitActions: exitActions, rest: [given])
    }
    
    func testEmptyNode() {
        let node = PreemptiveTableNode()
        XCTAssertEqual(0, node.finalised().errors.count)
        XCTAssertEqual(0, node.finalised().output.count)
    }
    
    func testNodeWithSingleDefineSingleInvalidPredicate() {
        let node = tableNode(given: s1, match: Match(any: P.a, P.a), when: e1, then: s2)
        let result = node.finalised()
        XCTAssertEqual(1, result.errors.count)
        XCTAssertTrue(result.errors.first is MatchError)
    }
    
    let pr = PredicateResult(predicates: Set([P.a].erase()), rank: 1)
    
    func testNodeWithSingleDefineSingleValidPredicate() {
        let node = tableNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let result = node.finalised()
        XCTAssertEqual(0, result.errors.count)
        
        guard assertCount(actual: result.output.count, expected: 1) else { return }
        
        let expected = makeOutput(state: s1, predicates: pr, event: e1, nextState: s2)
        assertEqual(expected, result.output[0])
    }
    
    func testNodeWithDuplicateDefines() {
        let d1 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let result = PreemptiveTableNode(rest: [d1, d1, d1]).finalised()
        
        guard let error = firstDuplicatesError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        guard assertCount(actual: result.errors.count, expected: 1)    else { return }
        guard assertCount(actual: error.duplicates.count, expected: 3) else { return }
                
        assertDupe(error.duplicates[0], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(error.duplicates[1], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(error.duplicates[2], expected: (s1, pr, Match(any: P.a), e1, s2))
    }
    
    func testNodeWithLogicalClash() {
        let d1 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let d2 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s1)
        let result = PreemptiveTableNode(rest: [d1, d2]).finalised()
        
        guard let error = firstLogicalClashError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        guard assertCount(actual: result.errors.count, expected: 1) else { return }
        guard assertCount(actual: error.clashes.count, expected: 2) else { return }
        
        assertDupe(error.clashes[0], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(error.clashes[1], expected: (s1, pr, Match(any: P.a), e1, s1))
    }

    func testNodeWithImplicitMatchDuplicate() {
        let d1 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let d2 = defineNode(given: s1, match: Match(any: Q.a), when: e1, then: s2)
        let result = PreemptiveTableNode(rest: [d1, d2]).finalised()
        
        guard let error = firstDuplicatesError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        guard assertCount(actual: result.errors.count, expected: 1)    else { return }
        guard assertCount(actual: error.duplicates.count, expected: 2) else { return }
        
        let firstDupe = error.duplicates.first { $0.2 == Match(any: P.a) }
        let secondDupe = error.duplicates.first { $0.2 == Match(any: Q.a) }
        
        let pr = PredicateResult(predicates: Set([P.a, Q.a].erase()), rank: 1)
        
        assertDupe(firstDupe, expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(secondDupe, expected: (s1, pr, Match(any: Q.a), e1, s2))
    }
    
    func testNodeWithImplicitMatchRemovesDuplicateWithLowerRank() {
        func assertRemovesLowRankDuplicate(
            subnodes: [any Node<PreemptiveTableNode.Input>],
            xctLine xl: UInt = #line
        ) {
            let tnr = PreemptiveTableNode(rest: subnodes).finalised()
            
            guard assertCount(actual: tnr.errors.count, expected: 0, line: xl) else { return }
            guard assertCount(actual: tnr.output.count, expected: 2, line: xl) else { return }
            
            let pr1 = PredicateResult(predicates: Set([P.a].erase()), rank: 1)
            let pr2 = PredicateResult(predicates: Set([P.b].erase()), rank: 0)
            
            let expected1 = makeOutput(state: s1, predicates: pr1, event: e1, nextState: s2)
            let expected2 = makeOutput(state: s1, predicates: pr2, event: e1, nextState: s2)
            
            assertEqual(expected1, tnr.output.first { $0.predicates == pr1 }, xctLine: xl)
            assertEqual(expected2, tnr.output.first { $0.predicates == pr2 }, xctLine: xl)
        }
        
        let d1 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let d2 = defineNode(given: s1, match: Match(), when: e1, then: s2)

        assertRemovesLowRankDuplicate(subnodes: [d1, d2])
        assertRemovesLowRankDuplicate(subnodes: [d2, d1])
    }
    
    func testNodeWithUniqueDefines() {
        let d1 = defineNode(given: s1, match: Match(any: P.a), when: e1, then: s2)
        let d2 = defineNode(given: s2, match: Match(any: Q.a), when: e1, then: s2)
        
        let result = PreemptiveTableNode(rest: [d1, d2]).finalised()
        
        guard assertCount(actual: result.errors.count, expected: 0) else { return }
        guard assertCount(actual: result.output.count, expected: 4) else { return }
        
        let firstTwo = result.output.prefix(2).map(\.predicates)
        let lastTwo = result.output.suffix(2).map(\.predicates)
        
        XCTAssert(firstTwo.allSatisfy { $0.predicates.contains(P.a.erase()) })
        XCTAssert(lastTwo.allSatisfy { $0.predicates.contains(Q.a.erase()) })
    }
    
    // TODO: Match rank clashes
    // TODO: Dupes and clashes not grouped together yet
    // TODO: LazyTableNode
}

extension Collection {
    func executeAll() where Element == DefaultIO {
        map(\.actions).flattened.forEach { $0() }
    }
    
    func executeAll() where Element == Action {
        forEach { $0() }
    }
}

protocol DefaultIONode: Node where Output == DefaultIO, Input == Output {
    func copy() -> Self
}

extension ActionsNode: DefaultIONode {
    func copy() -> Self {
        ActionsNode(actions: actions, rest: rest) as! Self
    }
}

extension ThenNode: DefaultIONode {
    func copy() -> Self {
        ThenNode(state: state, rest: rest) as! Self
    }
}

extension WhenNode: DefaultIONode {
    func copy() -> Self {
        WhenNode(events: events, rest: rest) as! Self
    }
}

extension MatchNode: DefaultIONode {
    func copy() -> Self {
        MatchNode(match: match, rest: rest) as! Self
    }
}

typealias MSES = (match: Match, state: AnyTraceable, event: AnyTraceable, nextState: AnyTraceable)

extension [MSES] {
    var description: String {
        reduce(into: ["\n"]) {
            $0.append("(\($1.match), \($1.state), \($1.event), \($1.nextState))")
        }.joined(separator: "\n")
    }
}

extension AnyTraceable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(base: AnyHashable(value), file: "null", line: -1)
    }
}

extension AnyTraceable: CustomStringConvertible {
    public var description: String {
        base.description
    }
}
