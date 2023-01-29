//
//  FSMTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import XCTest
@testable import FiniteStateMachine

class FSMTests: GenericTests {
    var didPass = false
    
    func pass() {
        didPass = true
    }
    
    func fail() {
        XCTFail()
    }
    
    func testHandlEvent() {
        let fsm = GenericFSM<State, Event>(state: .a)
        fsm.buildTransitions {
            Given(.a) | When(.g) | Then(.b) | Action(pass)
            Given(.a) | When(.h) | Then(.b) | Action(fail)
        }
        fsm.handleEvent(.g)
        XCTAssertTrue(didPass)
        XCTAssertEqual(fsm.state, .b)
    }
}
