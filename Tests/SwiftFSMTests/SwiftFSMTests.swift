//
//  SwiftFSMTests.swift
//  
//
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
@testable import SwiftFSM

final class SwiftFSMTests: XCTestCase, TransitionBuilderProtocol {
    enum State: AnyHashable, AnyHashableEnum { case s1 }
    enum Event: AnyHashable, AnyHashableEnum { case e1, e2 }
    
    var output = ""
    
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
            entryActions { self.output += "1" }
        }
        
        rows.allEntryActions.executeAll()
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", output)
        XCTAssertEqual(State.s1, rows[0].state)
    }
    
    func testDefineCanAcceptExitActions() {
        let rows = define(.s1) {
            exitActions { self.output += "1" }
        }
        
        rows.allExitActions.executeAll()
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", output)
        XCTAssertEqual(State.s1, rows[0].state)
    }
    
    func testEmptyFinalActionsFinalisesToEmptyArray() {
        let n = FinalActionsNode(actions: [])
        XCTAssertTrue(n.finalise().isEmpty)
    }
    
    
    var finalActionsNode: FinalActionsNode {
        FinalActionsNode(actions: [{ self.output += "1" },
                                   { self.output += "2" }])
    }
    
    func testFinalActionsFinalisesWithCorrectActions() {
        let n = finalActionsNode
        n.finalise().executeAll()
        XCTAssertEqual("12", output)
    }
    
    func assertEmptyFinalThen(
        _ t: FinalThenNode,
        line: UInt = #line
    ) {
        let result = t.finalise()
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(State.s1, result[0].state, line: line)
        XCTAssertTrue(result[0].actions.isEmpty, line: line)
    }
    
    func testEmptyFinalThenNodeFinalisesWithoutActions() {
        let t = FinalThenNode(state: State.s1,
                              rest: [])
        assertEmptyFinalThen(t)
    }
    
    func testFinalThenNodeAcceptsEmptyFinalActionsNode() {
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
        XCTAssertEqual(expected, output, line: line)
    }
    
    func testFinalThenNodeFinalisesWithCorrectActions() {
        let t = FinalThenNode(state: State.s1,
                              rest: [finalActionsNode])
        
        assertFinalThenNodeWithActions(expected: "12", t)
    }
    
    func testActionsCanBeSetAfterInitialisation() {
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
        
        guard result.count == 2 else {
            XCTFail("Incorrect count: \(result.count) instead of 2", line: line)
            return
        }
        
        XCTAssertEqual(state, result[0].state, line: line)
        XCTAssertEqual(state, result[1].state, line: line)
        
        XCTAssertEqual(Event.e1, result[0].event, line: line)
        XCTAssertEqual(Event.e2, result[1].event, line: line)
        
        XCTAssertEqual(actionsCount, result[0].actions.count, line: line)
        XCTAssertEqual(actionsCount, result[1].actions.count, line: line)
        
        result[0].actions.executeAll()
        result[1].actions.executeAll()
        
        XCTAssertEqual(actionsOutput, output, line: line)
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
    
    func testThenNodeCanBeSetAfterInitialisation() {
        var w = FinalWhenNode(events: [Event.e1, Event.e2])
        w.rest.append(finalThenNode)
        w.rest.append(finalThenNode)
        assertFinalWhenNodeWithActions(w)
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

protocol AnyHashableEnum { }; extension AnyHashableEnum {
    init?(rawValue: String) {  nil  }
    var rawValue: String { String(describing: self) }
    typealias RawValue = String
}
