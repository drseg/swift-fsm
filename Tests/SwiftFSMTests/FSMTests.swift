//
//  FSMTests.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation
import XCTest
@testable import SwiftFSM

final class FSMTests: XCTestCase {
    let s1: AnyHashable = "S1"
    
    func testSuccessfulInit() throws {
        let fsm = try FSM<Int, Double>(initialState: 1)
        XCTAssertEqual(1, fsm.state)
    }
    
    func testSameTypeErrorOnInit() throws {
        XCTAssertThrowsError(try FSM<Int, Int>(initialState: 1)) {
            XCTAssertTrue($0 is StateEventClash)
        }
    }
    
    func testNoErrorIfStateAndEventAreAnyHashable() throws {
        XCTAssertNoThrow(try FSM<AnyHashable, AnyHashable>(initialState: 1))
    }
}
