//
//  FSMTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import XCTest
@testable import FiniteStateMachine

class FSMTests: SafeTests {
    var didPass = false
    
    func pass() {
        didPass = true
    }
    
    func fail() {
        XCTFail()
    }
    
    func testHandlEvent() {
        let fsm = GenericFSM<State, Event>(initialState: .a)
        fsm.buildTransitions {
            G(.a) | W(.h) | T(.b) | A(fail)
            G(.a) | W(.g) | T(.c) | A(pass)
        }
        fsm.handleEvent(.g)
        XCTAssertTrue(didPass)
        XCTAssertEqual(fsm.state, .c)
    }
}
