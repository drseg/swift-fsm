//
//  FSMTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

final class FSMTests: XCTestCase, TransitionBuilder {
    typealias State = Int
    typealias Event = Double
    
    var fsm: FSM<State, Event> = FSM(initialState: 1)
    
    func testSuccessfulInit() throws {
        XCTAssertEqual(1, fsm.state)
    }
    
    func assertThrowsError<T: Error>(
        _ type: T.Type,
        count: Int = 1,
        line: UInt = #line,
        block: () throws -> ()
    ) {
        XCTAssertThrowsError(try block(), line: line) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(count, errors?.count, line: line)
            XCTAssertTrue(errors?.first is T, String(describing: errors), line: line)
        }
    }
    
    func testBuildEmptyTable() throws {
        assertThrowsError(EmptyTableError.self) {
            try fsm.buildTable { }
        }
    }
    
    func testThrowsErrorsFromNodes() throws {
        assertThrowsError(EmptyBuilderError.self) {
            try fsm.buildTable { define(1) { } }
        }
    }
    
    func testThrowsNSObjectError() throws {
        let fsm1 = FSM<NSObject, Int>(initialState: NSObject())
        let fsm2 = FSM<Int, NSObject>(initialState: 1)
        
        assertThrowsError(NSObjectError.self) {
            try fsm1.buildTable {
                Syntax.Define(NSObject()) { Syntax.When(1) | Syntax.Then(NSObject()) }
            }
        }
        
        assertThrowsError(NSObjectError.self) {
            try fsm2.buildTable {
                Syntax.Define(1) { Syntax.When(NSObject()) | Syntax.Then(2) }
            }
        }
    }
    
    func testThrowsStateEventTypeClash() throws {
        assertThrowsError(TypeClashError.self) {
            try FSM<Int, Int>(initialState: 1).buildTable {
                Syntax.Define(1) { Syntax.When(1) | Syntax.Then(2) }
            }
        }
    }
    
    func testThrowsPredicateEventTypeClash() throws {
        assertThrowsError(TypeClashError.self) {
            try fsm.buildTable {
                Syntax.Define(1) {
                    Syntax.Matching(1) | Syntax.When(1.1) | Syntax.Then(2)
                }
            }
        }
        
        assertThrowsError(TypeClashError.self) {
            try fsm.buildTable {
                Syntax.Define(1) {
                    Syntax.Matching(1.1) | Syntax.When(1.1) | Syntax.Then(2)
                }
            }
        }
    }
    
    func testValidTableDoesNotThrow() throws {
        XCTAssertNoThrow(
            try fsm.buildTable {
                define(1) { when(1.1) | then(2) }
            }
        )
    }
    
    func testHandleEventWithoutEntryExitActions() {
        var actionsOutput = ""
        
        try! fsm.buildTable {
            define(1) {
                when(1.1) | then(2) | { actionsOutput = "pass" }
            }
        }
        
        fsm.handleEvent(1.1)
        XCTAssertEqual(2, fsm.state)
        XCTAssertEqual("pass", actionsOutput)
    }
    
    var actionsOutput = ""
    var entryActions: [() -> ()] { [{ self.actionsOutput += "<<" }] }
    var exitActions: [() -> ()] { [{ self.actionsOutput += ">>" }] }

    func testPerformsNoEntryAndExitActionsWithoutStateChange() {
        try! fsm.buildTable {
            define(1, entryActions: entryActions, exitActions: exitActions) {
                when(1.1) | then(1)
            }
        }
        
        fsm.handleEvent(1.1)
        XCTAssertEqual(1, fsm.state)
        XCTAssertEqual("", actionsOutput)
    }
}

extension Int: Predicate {
    public static var allCases: [Int] { [] }
}

extension Double: Predicate {
    public static var allCases: [Double] { [] }
}
