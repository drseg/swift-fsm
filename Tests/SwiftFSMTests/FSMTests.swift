//
//  SwiftFSMTests.swift
//  
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
@testable import SwiftFSM

class FSMNodeTests: XCTestCase {
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
    
    var finalActionsNode: ActionsNode {
        ActionsNode(actions: actions)
    }
    
    var finalThenNode: ThenNode {
        ThenNode(state: s1,
                      rest: [finalActionsNode])
    }
    
    var finalWhenNode: WhenNode {
        WhenNode(events: [e1, e2],
                      rest: [finalThenNode])
    }
    
    func assertEqual(
        _ lhs: MatchNode.Output,
        _ rhs: MatchNode.Output,
        line: UInt = #line
    ) {
        XCTAssertTrue(lhs.match == rhs.match &&
                      lhs.event == rhs.event &&
                      lhs.state == rhs.state,
                      "\(lhs) does not equal \(rhs)",
                      line: line)
    }
    
    func assertEqual(lhs: [SES], rhs: [SES], line: UInt) {
        XCTAssertTrue(isEqual(lhs: lhs, rhs: rhs),
    """
    \n\nActual: \(lhs.description)
    
    did not equal expected: \(rhs.description)
    """,
                      line: line)
    }
    
    
    func isEqual(lhs: [SES], rhs: [SES]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (lhs, rhs) in zip(lhs, rhs) {
            guard lhs.state == rhs.state &&
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
    
    func assertEmptyFinalThen(
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
    
    func assertFinalThenWithActions(
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
        
        XCTAssertTrue(f.0.isEmpty, "Not empty: \(f.0)", line: line)
        XCTAssertTrue(f.1.isEmpty, "Not empty: \(f.1)", line: line)
    }
    
    func assertEmptyNodeWithError(_ n: some NeverEmptyNode, line: UInt = #line) {
        let finalised = n.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        XCTAssertTrue(result.isEmpty, line: line)
        XCTAssertEqual(errors as? [EmptyBuilderError],
                       [EmptyBuilderError(caller: n.caller,
                                          file: n.file,
                                          line: n.line)],
                       line: line)
    }
    
    func assertFinalWhen(
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
    
    func assertCount(actual: Int, expected: Int, line: UInt) -> Bool {
        guard actual == expected else {
            XCTFail("Incorrect count: \(actual) instead of \(expected)",
                    line: line)
            return false
        }
        return true
    }
    
    func assertFinalMatch(_ m: MatchNode, line: UInt = #line) {
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
        expected: [SES],
        actionsOutput: String,
        node: GivenNode,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { ($0.state, $0.event, $0.nextState) },
                    line: line)
        
        result.map(\.actions).flattened.executeAll()
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
        XCTAssertTrue(errors.isEmpty, line: line)
    }
    
    func assertDefineNode(
        expected: [SES],
        actionsOutput: String,
        node: DefineNode,
        line: UInt = #line
    ) {
        let finalised = node.finalised()
        let result = finalised.0
        let errors = finalised.1
        
        assertEqual(lhs: expected,
                    rhs: result.map { ($0.state, $0.event, $0.nextState) },
                    line: line)
        
        result.forEach {
            $0.entryActions.executeAll()
            $0.actions.executeAll()
            $0.exitActions.executeAll()
        }
        
        XCTAssertTrue(errors.isEmpty, line: line)
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
}

final class SwiftFSMTests: FSMNodeTests {
    func testTraceableEquality() {
        let t1 = randomisedTrace("cat")
        let t2 = randomisedTrace("cat")
        let t3 = randomisedTrace("bat")
        let t4: AnyTraceable = "cat"
        
        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1, t4)
        XCTAssertNotEqual(t1, t3)
    }
    
    func testTraceableHashingMatchesEquatable() {
        var randomCat: AnyTraceable { randomisedTrace("cat") }
        
        1000 * {
            let dict = [randomCat: randomCat]
            XCTAssertEqual(dict[randomCat], randomCat)
        }
    }
    
    func testTraceableDescription() {
        XCTAssertEqual(s1.description, "S1")
    }
    
    func testEmptyBlockError() {
        let error = EmptyBuilderError(file: "file", line: 10)
        
        XCTAssertEqual("testEmptyBlockError", error.caller)
        XCTAssertEqual(10, error.line)
        XCTAssertEqual("file", error.file)
    }
    
    func testEmptyFinalActions() {
        assertEmptyNodeWithoutError(ActionsNode(actions: []))
    }
    
    func testFinalActionsFinalisesCorrectly() {
        let n = finalActionsNode
        n.finalised().0.executeAll()
        XCTAssertEqual("12", actionsOutput)
        XCTAssertTrue(n.finalised().1.isEmpty)
    }
    
    func testNilThenNodeState() {
        assertEmptyFinalThen(
            ThenNode(state: nil, rest: []),
            thenState: nil
        )
    }
    
    func testEmptyFinalThenNode() {
        assertEmptyFinalThen(
            ThenNode(state: s1, rest: [])
        )
    }
    
    func testFinalThenNodeWithEmptyRest() {
        assertEmptyFinalThen(
            ThenNode(state: s1,
                          rest: [ActionsNode(actions: [])])
        )
    }
    
    func testFinalThenNodeFinalisesCorrectly() {
        assertFinalThenWithActions(
            expected: "12",
            ThenNode(state: s1, rest: [finalActionsNode])
        )
    }
    
    func testFinalThenNodeCanSetRestAfterInit() {
        var t = ThenNode(state: s1)
        t.rest.append(finalActionsNode)
        assertFinalThenWithActions(expected: "12", t)
    }
    
    func testFinalThenNodeFinalisesWithMultipleActionsNodes() {
        assertFinalThenWithActions(
            expected: "1212",
            ThenNode(state: s1, rest: [finalActionsNode,
                                       finalActionsNode])
        )
    }
    
    func testEmptyFinalWhenNode() {
        assertEmptyNodeWithoutError(WhenNode(events: [], rest: []))
    }
    
    func testEmptyFinalWhenNodeWithActions() {
        assertEmptyNodeWithoutError(WhenNode(events: [], rest: [finalThenNode]))
    }
    
    func testFinalWhenNodeWithEmptyRest() {
        assertFinalWhen(state: nil,
                        actionsCount: 0,
                        actionsOutput: "",
                        node: WhenNode(events: [e1, e2], rest: []),
                        line: #line)
    }
    
    func assertFinalWhenNodeWithActions(
        expected: String = "1212",
        _ w: WhenNode,
        line: UInt = #line
    ) {
        assertFinalWhen(state: s1,
                        actionsCount: 2,
                        actionsOutput: expected,
                        node: w,
                        line: line)
    }
    
    func testFinalWhenNodeFinalisesWithCorrectActions() {
        assertFinalWhenNodeWithActions(
            WhenNode(events: [e1, e2], rest: [finalThenNode])
        )
    }
    
    func testFinalWhenNodeCanSetRestAfterInit() {
        var w = WhenNode(events: [e1, e2])
        w.rest.append(finalThenNode)
        assertFinalWhenNodeWithActions(w)
    }
    
    func testEmptyFinalMatchNodeIsError() {
        assertEmptyNodeWithError(MatchNode(match: Match(),
                                                rest: [],
                                                caller: "caller",
                                                file: "file",
                                                line: 10))
    }
    
    func testFinalMatchNodeWithActions() {
        assertFinalMatch(MatchNode(match: Match(), rest: [finalWhenNode]))
    }
    
    func testFinalMatchNodeCanSetRestAfterInit() {
        var m = MatchNode(match: Match())
        m.rest.append(finalWhenNode)
        assertFinalMatch(m)
    }
    
    func testEmptyGivenNode() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: []))
    }
    
    func testGivenNodeWithEmptyStates() {
        assertEmptyNodeWithoutError(GivenNode(states: [], rest: [finalWhenNode]))
    }
    
    func testGivenNodeWithEmptyRest() {
        assertEmptyNodeWithoutError(GivenNode(states: [s1, s2], rest: []))
    }
    
    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let t = ThenNode(state: nil, rest: [finalActionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let expected = [(s1, e1, s1),
                        (s1, e2, s1),
                        (s2, e1, s2),
                        (s2, e2, s2)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: g)
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let t = ThenNode(state: s3, rest: [finalActionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: g)
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = ThenNode(state: s3, rest: [finalActionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        var g = GivenNode(states: [s1, s2])
        g.rest.append(w)
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "12121212",
                        node: g)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = ThenNode(state: s3, rest: [finalActionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w, w])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNode(expected: expected,
                        actionsOutput: "1212121212121212",
                        node: g)
    }
    
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
    
    func testDefineNodeWithNoActions() {
        let t = ThenNode(state: s3, rest: [])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let d = DefineNode(entryActions: [],
                           exitActions: [],
                           rest: [g])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeCanSetRestAfterInit() {
        let t = ThenNode(state: s3, rest: [])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        var d = DefineNode(entryActions: [],
                           exitActions: [])
        d.rest.append(g)
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
    }
    
    func testDefineNodeWithMultipleGivensWithEntryActionsAndExitActions() {
        let t = ThenNode(state: s3, rest: [finalActionsNode])
        let w = WhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [g, g])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3),
                        (s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertDefineNode(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    func testDefineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() {
        let w = WhenNode(events: [e1, e2], rest: [])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [g])
        
        let expected = [(s1, e1, s1),
                        (s1, e2, s1),
                        (s2, e1, s2),
                        (s2, e2, s2)]
        
        assertDefineNode(expected: expected,
                         actionsOutput: "",
                         node: d)
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

typealias SES = (state: AnyTraceable, event: AnyTraceable, nextState: AnyTraceable)

extension [SES] {
    var description: String {
        reduce(into: ["\n"]) {
            $0.append("(\($1.state), \($1.event), \($1.nextState))")
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
