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
        _ actual: any Collection,
        expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        guard actual.count == expected else {
            XCTFail("Incorrect count: \(actual.count) instead of \(expected)",
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
        g: AnyTraceable,
        m: Match,
        w: AnyTraceable,
        t: AnyTraceable,
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
    
    func assertActions(_ actions: [() -> ()]?, expectedOutput: String?, line: UInt = #line) {
        actions?.executeAll()
        XCTAssertEqual(actionsOutput, expectedOutput, line: line)
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
        let node = TransitionNode(rest: [defineNode(g: g, m: m, w: w, t: t, exit: exitActions)])
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
        let d1 = defineNode(g: s1, m: m, w: e1, t: s1, entry: [], exit: [])
        let d2 = defineNode(g: s2, m: m, w: e1, t: s3, entry: entryActions, exit: [])
        let result = TransitionNode(rest: [d1, d2]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        assertResult(result.output[0], s1, m, e1, s1, "12")
        assertResult(result.output[1], s2, m, e1, s3, "12")
    }
    
    func testAddsEntryActionsForStateChange() {
        let d1 = defineNode(g: s1, m: m, w: e1, t: s2)
        let d2 = defineNode(g: s2, m: m, w: e1, t: s3, entry: entryActions)
        let result = TransitionNode(rest: [d1, d2]).finalised()
        
        XCTAssertTrue(result.errors.isEmpty)
        guard assertCount(result.output, expected: 2) else { return }
        
        assertResult(result.output[0], s1, m, e1, s2, "12<<")
        assertResult(result.output[1], s2, m, e1, s3, "12")
    }
}

class TableNodeTests<N: TableNodeProtocol>: DefineConsumer {
    typealias ExpectedTableNodeOutput = (state: AnyTraceable,
                                         pr: PredicateResult,
                                         event: AnyTraceable,
                                         nextState: AnyTraceable,
                                         actionsOutput: String)
    
    typealias TableNodeResult = (output: [TableNodeOutput], errors: [Error])
    typealias PossibleError = TableNodeProtocol.PossibleError
    typealias Key = TableNodeErrorKey
    
    enum P: Predicate { case a, b }
    enum Q: Predicate { case a, b }
    
    let pr = PredicateResult(predicates: Set([P.a].erased()), rank: 1)
    
    func tableNode(g: AnyTraceable, m: Match, w: AnyTraceable, t: AnyTraceable) -> N {
        .init(rest: [TransitionNode(rest: [defineNode(g: g, m: m, w: w, t: t)])])
    }
    
    func tableNode(rest: [any Node<DefineNode.Output>]) -> N {
        .init(rest: [TransitionNode(rest: rest)])
    }
    
    func predicateResult(_ ps: any Predicate..., rank: Int) -> PredicateResult {
        predicateResult(ps, rank: rank)
    }
    
    func predicateResult(_ ps: [any Predicate], rank: Int) -> PredicateResult {
        PredicateResult(predicates: Set(ps.erased()), rank: rank)
    }
    
    func assertEqual(
        _ lhs: ExpectedTableNodeOutput?,
        _ rhs: TableNodeOutput?,
        xctLine xl: UInt = #line
    ) {
        XCTAssertEqual(lhs?.state, rhs?.state, line: xl)
        XCTAssertEqual(lhs?.pr, rhs?.pr, line: xl)
        XCTAssertEqual(lhs?.event, rhs?.event, line: xl)
        XCTAssertEqual(lhs?.nextState, rhs?.nextState, line: xl)
        
        assertActions(rhs?.actions, expectedOutput: lhs?.actionsOutput, line: xl)
    }
    
    func makeOutput(
        state: AnyTraceable,
        predicates: any Predicate...,
        rank: Int,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actionsOutput: String = "12"
    ) -> ExpectedTableNodeOutput {
        (state: state,
         pr: predicateResult(predicates, rank: rank),
         event: event,
         nextState: nextState,
         actionsOutput: actionsOutput)
    }
    
    func makeOutput(
        state: AnyTraceable,
        predicates: PredicateResult,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actionsOutput: String = "12"
    ) -> ExpectedTableNodeOutput {
        (state: state,
         pr: predicates,
         event: event,
         nextState: nextState,
         actionsOutput: actionsOutput)
    }

    func assertDupe(
        _ dupe: PossibleError?,
        expected: PossibleError?,
        xctLine xl: UInt = #line
    ) {
        let message = "\(String(describing: dupe)) does not equal \(String(describing: expected))"
        guard let dupe, let expected else { XCTFail(message); return }
        
        XCTAssertTrue(expected == dupe, message, line: xl)
    }
    
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
        
    func testEmptyNode() {
        let node = tableNode(rest: [])
        
        XCTAssertEqual(0, node.finalised().errors.count)
        XCTAssertEqual(0, node.finalised().output.count)
    }
    
    func testNodeWithSingleDefineSingleInvalidPredicate() {
        let node = tableNode(g: s1, m: Match(any: P.a, P.a), w: e1, t: s2)
        let result = node.finalised()
        
        XCTAssertEqual(1, result.errors.count)
        XCTAssertTrue(result.errors.first is MatchError)
    }
    
    func testNodeWithSingleDefineSingleValidPredicate() {
        let node = tableNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let result = node.finalised()
        
        guard assertCount(result.errors, expected: 0) else { return }
        guard assertCount(result.output, expected: 1) else { return }
        
        let expected = makeOutput(state: s1, predicates: pr, event: e1, nextState: s2)
        assertEqual(expected, result.output[0])
    }
    
    func testNodeWithSingleDefineSingleEmptyPredicate() {
        let node = tableNode(g: s1, m: Match(), w: e1, t: s2)
        let result = node.finalised()
        
        guard assertCount(result.errors, expected: 0) else { return }
        guard assertCount(result.output, expected: 1) else { return }
        
        assertEqual(makeOutput(state: s1, predicates: PredicateResult(), event: e1, nextState: s2),
                    result.output[0])
    }
    
    func testNodeWithDuplicateDefines() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let result = tableNode(rest: [d1, d1, d1]).finalised()
        
        guard let error = firstDuplicatesError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        let duplicates = error.duplicates[Key(state: s1, pr: pr, event: e1)] ?? []
        
        guard assertCount(result.errors,    expected: 1) else { return }
        guard assertCount(error.duplicates, expected: 1) else { return }
        guard assertCount(duplicates,       expected: 3) else { return }
                
        assertDupe(duplicates[0], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(duplicates[1], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(duplicates[2], expected: (s1, pr, Match(any: P.a), e1, s2))
    }
    
    func testNodeWithLogicalClash() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s1)
        let result = tableNode(rest: [d1, d2]).finalised()
        
        guard let error = firstLogicalClashError(in: result) else {
            errorAssertionFailure(in: result); return
        }
                
        let clashes = error.clashes[Key(state: s1, pr: pr, event: e1)] ?? []
        
        guard assertCount(result.errors, expected: 1) else { return }
        guard assertCount(error.clashes, expected: 1) else { return }
        guard assertCount(clashes,       expected: 2) else { return }
        
        assertDupe(clashes[0], expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(clashes[1], expected: (s1, pr, Match(any: P.a), e1, s1))
    }
}

final class LazyTableNodeTests: TableNodeTests<LazyTableNode> {
    func testDuplicateDetection() {
        func makePE(
            s: AnyTraceable,
            p: PredicateResult,
            e: AnyTraceable,
            ns: AnyTraceable
        ) -> PossibleError {
            (state: s, pr: p, match: Match(), event: e, nextState: ns)
        }
        
        func assertDuplicates(_ lhs: PossibleError, _ rhs: PossibleError, line: UInt = #line) {
            XCTAssertTrue(LazyTableNode().areDuplicates(lhs, rhs), line: line)
        }
        
        func assertNotDuplicates(_ lhs: PossibleError, _ rhs: PossibleError, line: UInt = #line) {
            XCTAssertFalse(LazyTableNode().areDuplicates(lhs, rhs), line: line)
        }
        
        let pr2 = predicateResult(Q.a, rank: 1)
        
        let pe1 = makePE(s: s1, p: pr,  e: e1, ns: s2)
        let pe2 = makePE(s: s1, p: pr2, e: e1, ns: s2)
        
        assertDuplicates(pe1, pe1)
        assertDuplicates(pe1, pe2)
        
        let pr3 = predicateResult(P.a, Q.a, rank: 1)
        let pr4 = predicateResult(P.a, R.a, rank: 1)
        
        let pe3 = makePE(s: s1, p: pr3, e: e1, ns: s2)
        let pe4 = makePE(s: s1, p: pr4, e: e1, ns: s2)
        
        assertDuplicates(pe3, pe4)

        let pe11 = makePE(s: s2, p: pr, e: e1, ns: s2)
        let pe12 = makePE(s: s1, p: pr, e: e2, ns: s2)
        let pe13 = makePE(s: s1, p: pr, e: e1, ns: s3)
        let pe14 = makePE(s: s2, p: pr, e: e1, ns: s3)
        
        assertNotDuplicates(pe1, pe4)
        assertNotDuplicates(pe1, pe11)
        assertNotDuplicates(pe1, pe12)
        assertNotDuplicates(pe1, pe13)
        assertNotDuplicates(pe1, pe14)
    }
    
    func testNodeWithImplicitMatchDuplicate() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s1, m: Match(any: Q.a), w: e1, t: s2)
        let result = tableNode(rest: [d1, d2]).finalised()
        
        guard let error = firstDuplicatesError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        let pr1 = predicateResult(P.a, rank: 1)
        let pr2 = predicateResult(Q.a, rank: 1)

        let duplicates = error.duplicates.first?.value ?? []
        
        assertCount(result.errors,    expected: 1)
        assertCount(error.duplicates, expected: 1)
        assertCount(duplicates,       expected: 2)
        
        let firstDupe = duplicates.first  { $0.2 == Match(any: P.a) }
        let secondDupe = duplicates.first { $0.2 == Match(any: Q.a) }
        
        assertDupe(firstDupe, expected: (s1, pr1, Match(any: P.a), e1, s2))
        assertDupe(secondDupe, expected: (s1, pr2, Match(any: Q.a), e1, s2))
    }
    
    func testNodeWithUniqueDefines() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s2, m: Match(any: Q.a), w: e1, t: s3)
        
        let result = tableNode(rest: [d1, d2]).finalised()
        
        guard assertCount(result.errors, expected: 0) else { return }
        guard assertCount(result.output, expected: 2) else { return }
        
        let expected1 = makeOutput(state: s1, predicates: P.a, rank: 1, event: e1, nextState: s2)
        let expected2 = makeOutput(state: s2, predicates: Q.a, rank: 1, event: e1, nextState: s3)

        assertEqual(expected1, result.output[0])
        assertEqual(expected2, result.output[1])
    }
}

final class PreemptiveTableNodeTests: TableNodeTests<PreemptiveTableNode> {
    func testNodeWithImplicitMatchDuplicate() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s1, m: Match(any: Q.a), w: e1, t: s2)
        let result = tableNode(rest: [d1, d2]).finalised()
        
        guard let error = firstDuplicatesError(in: result) else {
            errorAssertionFailure(in: result); return
        }
        
        let pr = predicateResult(P.a, Q.a, rank: 1)
        let duplicates = error.duplicates[Key(state: s1, pr: pr, event: e1)] ?? []
        
        assertCount(result.errors,    expected: 1)
        assertCount(error.duplicates, expected: 1)
        assertCount(duplicates,       expected: 2)
        
        let firstDupe = duplicates.first  { $0.2 == Match(any: P.a) }
        let secondDupe = duplicates.first { $0.2 == Match(any: Q.a) }
        
        assertDupe(firstDupe, expected: (s1, pr, Match(any: P.a), e1, s2))
        assertDupe(secondDupe, expected: (s1, pr, Match(any: Q.a), e1, s2))
    }
    
    func testNodeWithImplicitMatchRemovesDuplicateWithLowerRank() {
        func assertRemovesLowRankDuplicate(
            subnodes: [any Node<DefineNode.Output>],
            xctLine xl: UInt = #line
        ) {
            let tnr = tableNode(rest: subnodes).finalised()
            
            assertCount(tnr.errors, expected: 0, line: xl)
            assertCount(tnr.output, expected: 2, line: xl)
            
            let pr1 = predicateResult(P.a, rank: 1)
            let pr2 = predicateResult(P.b, rank: 0)
            
            let expected1 = makeOutput(state: s1, predicates: pr1, event: e1, nextState: s2)
            let expected2 = makeOutput(state: s1, predicates: pr2, event: e1, nextState: s2)
            
            assertEqual(expected1, tnr.output.first { $0.pr == pr1 }, xctLine: xl)
            assertEqual(expected2, tnr.output.first { $0.pr == pr2 }, xctLine: xl)
        }
        
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s1, m: Match(), w: e1, t: s2)

        assertRemovesLowRankDuplicate(subnodes: [d1, d2])
        assertRemovesLowRankDuplicate(subnodes: [d2, d1])
    }
    
    func testNodeWithUniqueDefines() {
        let d1 = defineNode(g: s1, m: Match(any: P.a), w: e1, t: s2)
        let d2 = defineNode(g: s2, m: Match(any: Q.a), w: e1, t: s3)
        
        let result = tableNode(rest: [d1, d2]).finalised()
        
        assertCount(result.errors, expected: 0)
        assertCount(result.output, expected: 4)
        
        let firstTwo = result.output.prefix(2).map(\.pr)
        let lastTwo = result.output.suffix(2).map(\.pr)
        
        XCTAssert(firstTwo.allSatisfy { $0.predicates.contains(P.a.erase()) })
        XCTAssert(lastTwo.allSatisfy  { $0.predicates.contains(Q.a.erase()) })
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
