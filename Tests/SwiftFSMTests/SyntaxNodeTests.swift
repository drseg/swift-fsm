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
        _ lhs: DefaultIO?,
        _ rhs: DefaultIO?,
        line: UInt = #line
    ) {
        XCTAssertTrue(lhs?.match == rhs?.match &&
                      lhs?.event == rhs?.event &&
                      lhs?.state == rhs?.state,
                      "\(String(describing: lhs)) does not equal \(String(describing: rhs))",
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
        
        guard assertCount(result, expected: 1, line: line) else { return }
        
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
    
    @discardableResult
    func assertCount(
        _ actual: (any Collection)?,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        guard actual?.count ?? -1 == expected else {
            XCTFail("Incorrect count: \(actual?.count ?? -1) instead of \(expected)",
                    file: file,
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
                        
            guard assertCount(results, expected: 1, line: line) else { return }
            
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
        let finalised = ActionsNode(actions: [], rest: []).finalised()
        let output = finalised.output
        let errors = finalised.errors
        
        XCTAssertTrue(errors.isEmpty)
        guard assertCount(output, expected: 1) else { return }
        assertEqual((match: Match(), event: nil, state: nil, actions: actions), output.first)
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

class DefineConsumer: SyntaxNodeTests {
    func defineNode(
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        entry: [() -> ()]? = nil,
        exit: [() -> ()]? = nil
    ) -> DefineNode {
        let actions = ActionsNode(actions: actions)
        let then = ThenNode(state: t, rest: [actions])
        let when = WhenNode(events: [w], rest: [then])
        let match = MatchNode(match: m, rest: [when])
        let given = GivenNode(states: [g], rest: [match])
        return .init(entryActions: entry ?? [],
                     exitActions: exit ?? [],
                     rest: [given])
    }
    
    func assertActions(
        _ actions: [() -> ()]?,
        expectedOutput: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        actions?.executeAll()
        XCTAssertEqual(actionsOutput, expectedOutput, file: file, line: line)
        actionsOutput = ""
    }
}

class TransitionNodeTests: DefineConsumer {
    func testEmptyNode() {
        let node = TransitionNode()
        let finalised = node.finalised()
        XCTAssertTrue(finalised.output.isEmpty)
        XCTAssertTrue(finalised.errors.isEmpty)
    }
    
    func assertNode(
        g: AnyTraceable,
        m: Match,
        w: AnyTraceable,
        t: AnyTraceable,
        output: String,
        line: UInt = #line
    ) {
        let node = TransitionNode(rest: [defineNode(g, m, w, t, exit: exitActions)])
        let finalised = node.finalised()
        XCTAssertTrue(finalised.errors.isEmpty, line: line)
        guard assertCount(finalised.output, expected: 1, line: line) else { return }
        
        let result = finalised.output[0]
        assertResult(result, g, m, w, t, output, line)
    }
    
    func assertResult(
        _ result: TransitionNode.Output,
        _ g: AnyTraceable,
        _ m: Match,
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ output: String,
        _ line: UInt = #line
    ) {
        XCTAssertEqual(result.state, g, line: line)
        XCTAssertEqual(result.match, m, line: line)
        XCTAssertEqual(result.event, w, line: line)
        XCTAssertEqual(result.nextState, t, line: line)
        
        assertActions(result.actions, expectedOutput: output, line: line)
    }
    
    let m = Match()
    
    func testDoesNotAddExitActionsWithoutStateChange() {
        assertNode(g: s1, m: m, w: e1, t: s1, output: "12")
    }
    
    func testAddsExitActionsForStateChange() {
        assertNode(g: s1, m: m, w: e1, t: s2, output: "12>>")
    }
    
    func testdoesNotAddEntryActionsWithoutStateChange() {
        let d1 = defineNode(s1, m, e1, s1, entry: [], exit: [])
        let d2 = defineNode(s2, m, e1, s3, entry: entryActions, exit: [])
        let result = TransitionNode(rest: [d1, d2]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        assertResult(result.output[0], s1, m, e1, s1, "12")
        assertResult(result.output[1], s2, m, e1, s3, "12")
    }
    
    func testAddsEntryActionsForStateChange() {
        let d1 = defineNode(s1, m, e1, s2)
        let d2 = defineNode(s2, m, e1, s3, entry: entryActions)
        let result = TransitionNode(rest: [d1, d2]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        assertResult(result.output[0], s1, m, e1, s2, "12<<")
        assertResult(result.output[1], s2, m, e1, s3, "12")
    }
}

class PreemptiveTableNodeTests: DefineConsumer {
    typealias ExpectedTableNodeOutput = (state: AnyTraceable,
                                         predicates: Set<AnyPredicate>,
                                         event: AnyTraceable,
                                         nextState: AnyTraceable,
                                         actionsOutput: String)
    
    
    typealias PTN = PreemptiveTableNode
    typealias SVN = SemanticValidationNode
    typealias Key = PreemptiveTableNode.ImplicitClashesKey
    typealias TableNodeResult = (output: [PTN.Output], errors: [Error])
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    
    func tableNode(rest: [any Node<DefineNode.Output>]) -> PTN {
        .init(rest: [SVN(rest: [TransitionNode(rest: rest)])])
    }
    
    func makeOutput(
        _ g: AnyTraceable,
        _ p: [any Predicate],
        _ w: AnyTraceable,
        _ t: AnyTraceable,
        _ a: String = "12"
    ) -> ExpectedTableNodeOutput {
        (state: g, predicates: Set(p.erased()), event: w, nextState: t, actionsOutput: a)
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
        assertResult(result, expected: makeOutput(s1, [], e1, s2))
    }
    
    func testImplicitMatch() {
        let d1 = defineNode(s1, Match(), e1, s2)
        let d2 = defineNode(s1, Match(any: Q.a), e1, s3)
        let result = tableNode(rest: [d1, d2]).finalised()
        
        assertCount(result.output, expected: 2)
        
        assertResult(result, expected: makeOutput(s1, [Q.b], e1, s2))
        assertResult(result, expected: makeOutput(s1, [Q.a], e1, s3))
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
        
        assertError(result, expected: [makeOutput(s1, [P.a, Q.a], e1, s2),
                                       makeOutput(s1, [P.a, Q.a], e1, s3)])
    }
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
