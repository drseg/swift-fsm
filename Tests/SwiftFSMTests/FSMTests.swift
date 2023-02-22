//
//  SwiftFSMTests.swift
//  
//
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
@testable import SwiftFSM

final class SwiftFSMTests: XCTestCase, TransitionBuilderProtocol {
    enum State: AnyHashable, AnyHashableEnum { case s1, s2, s3 }
    enum Event: AnyHashable, AnyHashableEnum { case e1, e2, e3 }
    
    var actionsOutput = ""
    
    func testEmptyBlockError() {
        let error = EmptyBuilderBlockError(file: #file, line: 10)
        
        XCTAssertEqual("testEmptyBlockError", error.callingFunction)
        XCTAssertEqual(10, error.line)
        XCTAssertEqual(#file, error.file)
    }
    
    func testEmptyFinalActions() {
        let n = FinalActionsNode(actions: [])
        XCTAssertTrue(n.finalise().isEmpty)
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
        n.finalise().executeAll()
        XCTAssertEqual("12", actionsOutput)
    }
    
    func assertEmptyFinalThen(
        _ t: FinalThenNode,
        thenState: AnyHashable? = State.s1,
        line: UInt = #line
    ) {
        let result = t.finalise()
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(thenState, result[0].state, line: line)
        XCTAssertTrue(result[0].actions.isEmpty, line: line)
    }
    
    func testNilThenNodeState() {
        let t = FinalThenNode(state: nil, rest: [])
        assertEmptyFinalThen(t, thenState: nil)
    }
    
    func testEmptyFinalThenNode() {
        let t = FinalThenNode(state: State.s1,
                              rest: [])
        assertEmptyFinalThen(t)
    }
    
    func testFinalThenNodeWithEmptyRest() {
        let t = FinalThenNode(state: State.s1,
                              rest: [FinalActionsNode(actions: [])])
        assertEmptyFinalThen(t)
    }
    
    func assertFinalThenNodeWithActions(
        expected: String,
        _ t: FinalThenNode,
        line: UInt = #line
    ) {
        let result = t.finalise()
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(result[0].state, State.s1, line: line)
        result.first!.actions.executeAll()
        XCTAssertEqual(expected, actionsOutput, line: line)
    }
    
    func testFinalThenNodeFinalisesCorrectly() {
        let t = FinalThenNode(state: State.s1,
                              rest: [finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    func testFinalThenNodeCanSetRestAfterInitialisation() {
        var t = FinalThenNode(state: State.s1)
        t.rest.append(finalActionsNode)
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    // this is logically degenerate but the handling is reasonable
    func testFinalThenNodeFinalisesWithMultipleActionsNodes() {
        let t = FinalThenNode(state: State.s1,
                              rest: [finalActionsNode,
                                     finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "1212", t)
    }
    
    var finalThenNode: FinalThenNode {
        FinalThenNode(state: State.s1,
                      rest: [finalActionsNode])
    }
    
    func assertFinalWhenNode(
        state: AnyHashable?,
        actionsCount: Int,
        actionsOutput: String,
        node: FinalWhenNode,
        line: UInt
    ) {
        let result = node.finalise()
        
        guard assertCount(actual: result.count, expected: 2, line: line) else {
            return
        }
        
        (0..<2).forEach {
            XCTAssertEqual(state, result[$0].state, line: line)
            XCTAssertEqual(actionsCount, result[$0].actions.count, line: line)
            result[$0].actions.executeAll()
        }
        
        XCTAssertEqual(Event.e1, result[0].event, line: line)
        XCTAssertEqual(Event.e2, result[1].event, line: line)
                
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
        XCTAssertTrue(w.finalise().isEmpty)
    }
    
    func testEmptyFinalWhenNodeWithActions() {
        let w = FinalWhenNode(events: [], rest: [finalThenNode])
        XCTAssertTrue(w.finalise().isEmpty)
    }
    
    func testFinalWhenNodeWithEmptyRest() {
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [])
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
        assertFinalWhenNode(state: State.s1,
                            actionsCount: 2,
                            actionsOutput: expected,
                            node: w,
                            line: line)
    }
    
    func testFinalWhenNodeFinalisesWithCorrectActions() {
        let w = FinalWhenNode(events: [Event.e1, Event.e2],
                              rest: [finalThenNode])
        assertFinalWhenNodeWithActions(w)
    }
    
    func testFinalWhenNodeIgnoresExtraThenNodes() {
        let w = FinalWhenNode(events: [Event.e1, Event.e2],
                              rest: [finalThenNode,
                                     finalThenNode])
        assertFinalWhenNodeWithActions(w)
    }
    
    var finalWhenNode: FinalWhenNode {
        FinalWhenNode(events: [Event.e1, Event.e2],
                      rest: [finalThenNode])
    }
    
    func testFinalWhenNodeCanSetRestAfterInitialisation() {
        var w = FinalWhenNode(events: [Event.e1, Event.e2])
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
        let output = node.finalise()
        assertEqual(lhs: expected,
                    rhs: output.map { ($0.state, $0.event, $0.nextState) },
                    line: line)
        
        output.map(\.actions).flatten.executeAll()
        XCTAssertEqual(actionsOutput, actionsOutput, line: line)
    }
    
    func testEmptyGivenNode() {
        let g = GivenNode(states: [], rest: [])
        XCTAssertTrue(g.finalise().isEmpty)
    }
    
    func testGivenNodeWithEmptyStates() {
        let g = GivenNode(states: [], rest: [finalWhenNode])
        XCTAssertTrue(g.finalise().isEmpty)
    }
    
    func testGivenNodeWithEmptyRest() {
        let g = GivenNode(states: [State.s1, State.s2], rest: [])
        XCTAssertTrue(g.finalise().isEmpty)
    }
        
    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let t = FinalThenNode(state: nil, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let expected = [
            (State.s1, Event.e1, State.s1),
            (State.s1, Event.e2, State.s1),
            (State.s2, Event.e1, State.s2),
            (State.s2, Event.e2, State.s2)
        ]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        var g = GivenNode(states: [State.s1, State.s2])
        g.rest.append(w)
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "12121212",
                              node: g)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w, w])
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertGivenNodeOutput(expected: expected,
                              actionsOutput: "1212121212121212",
                              node: g)
    }
    
    func testEmptyDefineNode() {
        let d = DefineNode(entryActions: [], exitActions: [], rest: [])
        XCTAssertTrue(d.finalise().isEmpty)
    }
    
    func testDefineNodeWithActionsButNoRest() {
        let d = DefineNode(entryActions: [{ }], exitActions: [{ }], rest: [])
        XCTAssertTrue(d.finalise().isEmpty)
    }
    
    func assertDefineNodeOutput(
        expected: [SES],
        actionsOutput: String,
        node: DefineNode,
        line: UInt = #line
    ) {
        let output = node.finalise()
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
        let t = FinalThenNode(state: State.s3, rest: [])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let d = DefineNode(entryActions: [],
                           exitActions: [],
                           rest: [g])
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
    
    func testDefineNodeCanSetRestAfterInitialisation() {
        let t = FinalThenNode(state: State.s3, rest: [])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        var d = DefineNode(entryActions: [],
                           exitActions: [])
        d.rest.append(g)
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
    
    func testDefineNodeWithMultipleGivensWithEntryActionsAndExitActions() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [g, g])
        
        let expected = [
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3),
            (State.s1, Event.e1, State.s3),
            (State.s1, Event.e2, State.s3),
            (State.s2, Event.e1, State.s3),
            (State.s2, Event.e2, State.s3)
        ]
        
        assertDefineNodeOutput(
            expected: expected,
            actionsOutput: "<<12>><<12>><<12>><<12>><<12>><<12>><<12>><<12>>",
            node: d
        )
    }
    
    func testDefineNodeDoesNotAddEntryAndExitActionsIfStateDoesNotChange() {
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let d = DefineNode(entryActions: entryActions,
                           exitActions: exitActions,
                           rest: [g])
        
        let expected = [
            (State.s1, Event.e1, State.s1),
            (State.s1, Event.e2, State.s1),
            (State.s2, Event.e1, State.s2),
            (State.s2, Event.e2, State.s2)
        ]
        
        assertDefineNodeOutput(expected: expected,
                               actionsOutput: "",
                               node: d)
    }
}

typealias SES = (state: AnyHashable, event: AnyHashable, nextState: AnyHashable)

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

extension AnyHashable: ExpressibleByStringInterpolation {
    public typealias StringLiteralType = String
    
    public init(stringLiteral: String) {
        self = AnyHashable(stringLiteral)
    }
}

extension [SES] {
    var description: String {
        reduce(into: ["\n"]) {
            $0.append("(\($1.state), \($1.event), \($1.nextState))")
        }.joined(separator: "\n")
    }
}

protocol AnyHashableEnum: RawRepresentable, CustomStringConvertible
where RawValue == AnyHashable { }

extension AnyHashableEnum {
    init?(rawValue: AnyHashable) { nil }
    
    var description: String {
        String(describing: rawValue.base)
    }
}
