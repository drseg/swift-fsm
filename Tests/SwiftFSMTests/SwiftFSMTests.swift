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
    enum Event: AnyHashable, AnyHashableEnum { case e1 }
    
    func testDefineWithEmptyBlockHasSingleRowWithError() {
        let line = #line; let rows = define(.s1) { }
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual(1, rows.first?.errors.count)
        
        let error = rows.first!.errors.first!
        XCTAssertEqual(error.callingFunction, "define")
        XCTAssertEqual(error.line, line)
        XCTAssertEqual(error.file, #file)
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
        var output = ""
        let rows = define(.s1) {
            entryActions { output += "1" }
        }
        
        rows.allEntryActions.executeAll()
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", output)
        XCTAssertEqual(State.s1, rows[0].state)
    }
    
    func testDefineCanAcceptExitActions() {
        var output = ""
        let rows = define(.s1) {
            exitActions { output += "1" }
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
    
    var output = ""
    
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
        XCTAssertEqual(result[0].state, State.s1, line: line)
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
    
    func testFinalWhenNodeAcceptsEmptyThenNode() {
        let w = FinalWhenNode(events: [Event.e1], rest: [])
        let result = w.finalise()
        
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(result[0].state, nil)
        XCTAssertEqual(result[0].events, [Event.e1])
        XCTAssertEqual(0, result.first!.actions.count)
    }
    
    func assertFinalWhenNodeWithActions(
        expected: String,
        _ w: FinalWhenNode,
        line: UInt = #line
    ) {
        let result = w.finalise()
        XCTAssertEqual(1, result.count, line: line)
        XCTAssertEqual(result[0].state, State.s1, line: line)
        XCTAssertEqual(result[0].events, [Event.e1], line: line)

        result[0].actions.executeAll()
        XCTAssertEqual(expected, output, line: line)
    }
    
    func testFinalWhenNodeFinalisesWithCorrectActions() {
        let w = FinalWhenNode(events: [Event.e1], rest: [finalThenNode])
        assertFinalWhenNodeWithActions(expected: "12", w)
    }
    
    func testThenNodeCanBeSetAfterInitialisation() {
        var w = FinalWhenNode(events: [Event.e1])
        w.rest.append(finalThenNode)
        assertFinalWhenNodeWithActions(expected: "12", w)
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
