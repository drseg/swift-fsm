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
    
    func testBuildEmptyTable() throws {
        XCTAssertThrowsError(
            try fsm.buildTable { define(1) { } }
        ) {
            let error = $0 as? CompoundError
            XCTAssertNotNil(error)
            XCTAssertEqual(1, error?.errors.count)
            XCTAssertTrue(error?.errors.first is EmptyBuilderError)
        }
    }
}
