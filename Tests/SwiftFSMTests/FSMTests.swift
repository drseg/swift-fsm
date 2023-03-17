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
    
    var fsm: FSM<State, Event> {
        FSM(initialState: 1)
    }
    
    func testSuccessfulInit() throws {
        XCTAssertEqual(1, fsm.state)
    }
    
    func assertThrowsError<T: Error>(
        _ type: T.Type,
        count: Int = 1,
        line: UInt = #line,
        block: () throws -> ()
    ) {
        XCTAssertThrowsError(try block()) {
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
}
