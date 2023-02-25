//
//  SwiftFSMTests.swift
//  
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
@testable import SwiftFSM

final class SwiftFSMTests: XCTestCase {
    let s1: AnyTraceable = "S1", s2: AnyTraceable = "S2", s3: AnyTraceable = "S3"
    let e1: AnyTraceable = "E1", e2: AnyTraceable = "E2", e3: AnyTraceable = "E3"
    
    var actionsOutput = ""
    
    func randomisedTrace(_ base: String) -> AnyTraceable {
        AnyTraceable(base: base,
                     file: UUID().uuidString,
                     line: Int.random(in: 0...Int.max))
    }
    
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
        let error = EmptyBuilderBlockError(file: #file, line: 10)
        
        XCTAssertEqual("testEmptyBlockError", error.caller)
        XCTAssertEqual(10, error.line)
        XCTAssertEqual(#file, error.file)
    }
    
    func testEmptyFinalActions() {
        let n = FinalActionsNode(actions: [])
        XCTAssertTrue(n.finalised().0.isEmpty)
    }
    
    var actions: [Action] {
        [{ self.actionsOutput += "1" },
         { self.actionsOutput += "2" }]
    }
    
    var finalActionsNode: FinalActionsNode {
        FinalActionsNode(actions: actions)
    }
    
    func testFinalActionsFinalisesCorrectly() {
        let n = finalActionsNode
        n.finalised().0.executeAll()
        XCTAssertEqual("12", actionsOutput)
    }
    
    func assertEmptyFinalThen(
        _ t: FinalThenNode,
        thenState: AnyTraceable? = "S1",
        line: UInt = #line
    ) {
        let result = t.finalised().0
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(thenState, result[0].state, line: line)
        XCTAssertTrue(result[0].actions.isEmpty, line: line)
    }
    
    func testNilThenNodeState() {
        let t = FinalThenNode(state: nil, rest: [])
        assertEmptyFinalThen(t, thenState: nil)
    }
    
    func testEmptyFinalThenNode() {
        let t = FinalThenNode(state: s1,
                              rest: [])
        assertEmptyFinalThen(t)
    }
    
    func testFinalThenNodeWithEmptyRest() {
        let t = FinalThenNode(state: s1,
                              rest: [FinalActionsNode(actions: [])])
        assertEmptyFinalThen(t)
    }
    
    func assertFinalThenNodeWithActions(
        expected: String,
        _ t: FinalThenNode,
        line: UInt = #line
    ) {
        let result = t.finalised().0
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(result[0].state, s1, line: line)
        result.first!.actions.executeAll()
        XCTAssertEqual(expected, actionsOutput, line: line)
    }
    
    func testFinalThenNodeFinalisesCorrectly() {
        let t = FinalThenNode(state: s1,
                              rest: [finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    func testFinalThenNodeCanSetRestAfterInitialisation() {
        var t = FinalThenNode(state: s1)
        t.rest.append(finalActionsNode)
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    // this is logically degenerate but the handling is reasonable
    func testFinalThenNodeFinalisesWithMultipleActionsNodes() {
        let t = FinalThenNode(state: s1,
                              rest: [finalActionsNode,
                                     finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "1212", t)
    }
    
    var finalThenNode: FinalThenNode {
        FinalThenNode(state: s1,
                      rest: [finalActionsNode])
    }
    
    func assertFinalWhenNode(
        state: AnyTraceable?,
        actionsCount: Int,
        actionsOutput: String,
        node: FinalWhenNode,
        line: UInt
    ) {
        let result = node.finalised().0
        
        guard assertCount(actual: result.count, expected: 2, line: line) else {
            return
        }
        
        (0..<2).forEach {
            XCTAssertEqual(state, result[$0].state, line: line)
            XCTAssertEqual(actionsCount, result[$0].actions.count, line: line)
            result[$0].actions.executeAll()
        }
        
        XCTAssertEqual(e1, result[0].event, line: line)
        XCTAssertEqual(e2, result[1].event, line: line)
                
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
    
    func assertCount(actual: Int, expected: Int, line: UInt) -> Bool {
        guard actual == expected else {
            XCTFail("Incorrect count: \(actual) instead of \(expected)",
                    line: line)
            return false
        }
        return true
    }
    
    func testEmptyFinalWhenNode() {
        let w = FinalWhenNode(events: [], rest: [])
        XCTAssertTrue(w.finalised().0.isEmpty)
    }
    
    func testEmptyFinalWhenNodeWithActions() {
        let w = FinalWhenNode(events: [], rest: [finalThenNode])
        XCTAssertTrue(w.finalised().0.isEmpty)
    }
    
    func testFinalWhenNodeWithEmptyRest() {
        let w = FinalWhenNode(events: [e1, e2], rest: [])
        assertFinalWhenNode(state: nil,
                            actionsCount: 0,
                            actionsOutput: "",
                            node: w,
                            line: #line)
    }
    
    func assertFinalWhenNodeWithActions(
        expected: String = "1212",
        _ w: FinalWhenNode,
        line: UInt = #line
    ) {
        assertFinalWhenNode(state: s1,
                            actionsCount: 2,
                            actionsOutput: expected,
                            node: w,
                            line: line)
    }
    
    func testFinalWhenNodeFinalisesWithCorrectActions() {
        let w = FinalWhenNode(events: [e1, e2],
                              rest: [finalThenNode])
        assertFinalWhenNodeWithActions(w)
    }
    
    func testFinalWhenNodeIgnoresExtraThenNodes() {
        let w = FinalWhenNode(events: [e1, e2],
                              rest: [finalThenNode,
                                     finalThenNode])
        assertFinalWhenNodeWithActions(w)
    }
    
    var finalWhenNode: FinalWhenNode {
        FinalWhenNode(events: [e1, e2],
                      rest: [finalThenNode])
    }
    
    func testFinalWhenNodeCanSetRestAfterInitialisation() {
        var w = FinalWhenNode(events: [e1, e2])
        w.rest.append(finalThenNode)
        w.rest.append(finalThenNode)
        assertFinalWhenNodeWithActions(w)
    }
    
    func assertGivenNodeOutput(
        expected: [SES],
        actionsOutput: String,
        node: GivenNode,
        line: UInt = #line
    ) {
        let output = node.finalised().0
        assertEqual(lhs: expected,
                    rhs: output.map { ($0.state, $0.event, $0.nextState) },
                    line: line)
        
        output.map(\.actions).flattened.executeAll()
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
    
    func testEmptyGivenNode() {
        let g = GivenNode(states: [], rest: [])
        XCTAssertTrue(g.finalised().0.isEmpty)
    }
    
    func testGivenNodeWithEmptyStates() {
        let g = GivenNode(states: [], rest: [finalWhenNode])
        XCTAssertTrue(g.finalised().0.isEmpty)
    }
    
    func testGivenNodeWithEmptyRest() {
        let g = GivenNode(states: [s1, s2], rest: [])
        XCTAssertTrue(g.finalised().0.isEmpty)
    }
        
    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let t = FinalThenNode(state: nil, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let expected = [(s1, e1, s1),
                        (s1, e2, s1),
                        (s2, e1, s2),
                        (s2, e2, s2)]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let t = FinalThenNode(state: s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = FinalThenNode(state: s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        var g = GivenNode(states: [s1, s2])
        g.rest.append(w)
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = FinalThenNode(state: s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w, w])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "1212121212121212",
                              node: g)
    }
    
    func testEmptyDefineNode() {
        let d = DefineNode(entryActions: [], exitActions: [], rest: [])
        XCTAssertTrue(d.finalised().0.isEmpty)
    }
    
    func testDefineNodeWithActionsButNoRest() {
        let d = DefineNode(entryActions: [{ }], exitActions: [{ }], rest: [])
        XCTAssertTrue(d.finalised().0.isEmpty)
    }
    
    func assertDefineNodeOutput(
        expected: [SES],
        actionsOutput: String,
        node: DefineNode,
        line: UInt = #line
    ) {
        let output = node.finalised().0
        assertEqual(lhs: expected,
                    rhs: output.map { ($0.state, $0.event, $0.nextState) },
                    line: line)
        
        output.forEach {
            $0.entryActions.executeAll()
            $0.actions.executeAll()
            $0.exitActions.executeAll()
        }
        
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
    
    var entryActions: [Action] {
        [ { self.actionsOutput += "<"}, { self.actionsOutput += "<"} ]
    }
    
    var exitActions: [Action] {
        [ { self.actionsOutput += ">"}, { self.actionsOutput += ">"} ]
    }
    
    func testDefineNodeWithNoActions() {
        let t = FinalThenNode(state: s3, rest: [])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let d = DefineNode(entryActions: [],
                           exitActions: [],
                           rest: [g])
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
    
    func testDefineNodeCanSetRestAfterInitialisation() {
        let t = FinalThenNode(state: s3, rest: [])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        var d = DefineNode(entryActions: [],
                           exitActions: [])
        d.rest.append(g)
        
        let expected = [(s1, e1, s3),
                        (s1, e2, s3),
                        (s2, e1, s3),
                        (s2, e2, s3)]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
    
    func testDefineNodeWithMultipleGivensWithEntryActionsAndExitActions() {
        let t = FinalThenNode(state: s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [e1, e2], rest: [t])
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
        
        assertDefineNodeOutput(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    func testDefineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() {
        let w = FinalWhenNode(events: [e1, e2], rest: [])
        let g = GivenNode(states: [s1, s2], rest: [w])
        
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [g])
        
        let expected = [(s1, e1, s1),
                        (s1, e2, s1),
                        (s2, e1, s2),
                        (s2, e2, s2)]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
}

typealias SES = (state: AnyTraceable, event: AnyTraceable, nextState: AnyTraceable)

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

extension Collection where Element == Action {
    func executeAll() {
        forEach { $0() }
    }
}

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
