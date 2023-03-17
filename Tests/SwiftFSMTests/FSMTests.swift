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
        line: UInt = #line,
        block: () throws -> ()
    ) {
        XCTAssertThrowsError(try block()) {
            let errors = ($0 as? CompoundError)?.errors
            XCTAssertEqual(1, errors?.count, line: line)
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
}
