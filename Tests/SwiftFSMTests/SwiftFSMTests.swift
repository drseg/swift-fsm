//
//  SwiftFSMTests.swift
//  
//
//  Created by Daniel Segall on 19/02/2023.
//

import XCTest
@testable import SwiftFSM

final class SwiftFSMTests: XCTestCase, TransitionBuilderProtocol {
    enum State { case s1 }
    enum Event { case e1 }
    
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
        
        [a1, a2, a3].allEntryActions.forEach { $0() }
        
        XCTAssertEqual("12345", output)
    }
    
    func testExitActionsFunction() {
        var output = ""
        let a1 = exitActions { output += "1" }
        let a2 = exitActions({ output += "2" }, { output += "3" })
        let a3 = exitActions([{ output += "4" }, { output += "5" }])
        
        [a1, a2, a3].allExitActions.forEach { $0() }
        
        XCTAssertEqual("12345", output)
    }
    
    func testDefineCanAcceptEntryActions() {
        var output = ""
        let rows = define(.s1) {
            entryActions { output += "1" }
        }
        
        rows.allEntryActions.forEach { $0() }
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", output)
        XCTAssertEqual(AnyHashable(State.s1), rows[0].state)
    }
    
    func testDefineCanAcceptExitActions() {
        var output = ""
        let rows = define(.s1) {
            exitActions { output += "1" }
        }
        
        rows.allExitActions.forEach { $0() }
        
        XCTAssertEqual(1, rows.count)
        XCTAssertEqual("1", output)
        XCTAssertEqual(AnyHashable(State.s1), rows[0].state)
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
