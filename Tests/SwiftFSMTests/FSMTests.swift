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
    
    func testDefineWithEmptyBlockHasSingleRowWithError() {
        let line = #line; let rows = define(.s1) { }
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual(1, rows.first?.errors.count)
        
        let error = rows[0].errors[0]
        XCTAssertEqual("define", error.callingFunction)
        XCTAssertEqual(line, error.line)
        XCTAssertEqual(#file, error.file)
    }
    
    func testEntryActionsFunction() {
        var output = ""
        let a1 = entryActions { output += "1" }
        let a2 = entryActions({ output += "2" }, { output += "3" })
        let a3 = entryActions([{ output += "4" }, { output += "5" }])
        
        [a1, a2, a3].allEntryActions.executeAll()
        
        XCTAssertEqual("12345", output)
    }
    
    func testExitActionsFunction() {
        var output = ""
        let a1 = exitActions { output += "1" }
        let a2 = exitActions({ output += "2" }, { output += "3" })
        let a3 = exitActions([{ output += "4" }, { output += "5" }])
        
        [a1, a2, a3].allExitActions.executeAll()
        
        XCTAssertEqual("12345", output)
    }
    
    func testDefineCanAcceptEntryActions() {
        let rows = define(.s1) {
            entryActions { self.actionsOutput += "1" }
        }
        
        rows.allEntryActions.executeAll()
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", actionsOutput)
        XCTAssertEqual(State.s1, rows[0].state)
    }
    
    func testDefineCanAcceptExitActions() {
        let rows = define(.s1) {
            exitActions { self.actionsOutput += "1" }
        }
        
        rows.allExitActions.executeAll()
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", actionsOutput)
        XCTAssertEqual(State.s1, rows[0].state)
    }
    
    func testEmptyFinalActionsFinalisesToEmptyArray() {
        let n = FinalActionsNode(actions: [])
        XCTAssertTrue(n.finalise().isEmpty)
    }
    
    
    var finalActionsNode: FinalActionsNode {
        FinalActionsNode(actions: [{ self.actionsOutput += "1" },
                                   { self.actionsOutput += "2" }])
    }
    
    func testFinalActionsFinalisesWithCorrectActions() {
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
    
    func testFinalThenNodeWithEmptyFinalActionsNode() {
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
    
    func testFinalThenNodeFinalisesWithCorrectActions() {
        let t = FinalThenNode(state: State.s1,
                              rest: [finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    func testFinalThenNodeCanSetRestAfterInitialisation() {
        var t = FinalThenNode(state: State.s1)
        t.rest.append(finalActionsNode)
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    func testFinalThenNodeFinalisesWithMultipleActionsNodes() {
        // this is a degenerate case but the handling is reasonable
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
    
    func testFinalWhenNodeAcceptsEmptyThenNode() {
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
        node: GivenNode,
        expectedActionsOutput: String,
        expected: [GivenNode.Output],
        line: UInt = #line
    ) {
        func isEqual(lhs: [GivenNode.Output], rhs: [GivenNode.Output]) -> Bool {
            guard lhs.count == rhs.count else { return false }
            
            for (lhs, rhs) in zip(lhs, rhs) {
                guard lhs.state == rhs.state &&
                        lhs.event == rhs.event &&
                        lhs.nextState == rhs.nextState else { return false }
            }
            return true
        }
        
        let output = node.finalise()
        
        XCTAssertTrue(isEqual(lhs: output, rhs: expected),
"""
\n\nActual: \(output.description)

did not equal expected: \(expected.description)
""",
                      line: line)
        
        output.map(\.actions).flatten.executeAll()
        XCTAssertEqual(actionsOutput, expectedActionsOutput, line: line)
    }
    
    func testGivenNodeAcceptsEmptyFinalWhenNodes() {
        let g = GivenNode(states: [State.s1, State.s2], rest: [])
        XCTAssertTrue(g.finalise().isEmpty)
    }
        
    func testGivenNodeFinalisesFillingInEmptyNextStates() {
        let t = FinalThenNode(state: nil, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])

        let expected: [GivenNode.Output] = [
            (State.s1, Event.e1, State.s1, []),
            (State.s1, Event.e2, State.s1, []),
            (State.s2, Event.e1, State.s2, []),
            (State.s2, Event.e2, State.s2, [])
        ]

        assertGivenNodeOutput(node: g,
                              expectedActionsOutput: "12121212",
                              expected: expected)
    }
    
    func testGivenNodeFinalisesWithNextStates() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w])
        
        let expected: [GivenNode.Output] = [
            (State.s1, Event.e1, State.s3, []),
            (State.s1, Event.e2, State.s3, []),
            (State.s2, Event.e1, State.s3, []),
            (State.s2, Event.e2, State.s3, [])
        ]
        
        assertGivenNodeOutput(node: g,
                              expectedActionsOutput: "12121212",
                              expected: expected)
    }
    
    func testGivenNodeCanSetRestAfterInitialisation() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        var g = GivenNode(states: [State.s1, State.s2])
        g.rest.append(w)
        
        let expected: [GivenNode.Output] = [
            (State.s1, Event.e1, State.s3, []),
            (State.s1, Event.e2, State.s3, []),
            (State.s2, Event.e1, State.s3, []),
            (State.s2, Event.e2, State.s3, [])
        ]
        
        assertGivenNodeOutput(node: g,
                              expectedActionsOutput: "12121212",
                              expected: expected)
    }
    
    func testGivenNodeWithMultipleWhenNodes() {
        let t = FinalThenNode(state: State.s3, rest: [finalActionsNode])
        let w = FinalWhenNode(events: [Event.e1, Event.e2], rest: [t])
        let g = GivenNode(states: [State.s1, State.s2], rest: [w, w])
        
        let expected: [GivenNode.Output] = [
            (State.s1, Event.e1, State.s3, []),
            (State.s1, Event.e2, State.s3, []),
            (State.s1, Event.e1, State.s3, []),
            (State.s1, Event.e2, State.s3, []),
            (State.s2, Event.e1, State.s3, []),
            (State.s2, Event.e2, State.s3, []),
            (State.s2, Event.e1, State.s3, []),
            (State.s2, Event.e2, State.s3, [])
        ]
        
        assertGivenNodeOutput(node: g,
                              expectedActionsOutput: "1212121212121212",
                              expected: expected)
    }
}

extension [TableRow] {
    var allEntryActions: [() -> ()] {
        map(\.entryActions).flatten
    }
    
    var allExitActions: [() -> ()] {
        map(\.exitActions).flatten
    }
}

extension Collection where Element == () -> () {
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

extension [GivenNode.Output] {
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
