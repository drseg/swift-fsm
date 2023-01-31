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
    
    override func setUp() {
        didPass = false
    }
    
    func testHandlEvent() {
        let fsm = FSM<State, Event>(initialState: .a)
        fsm.buildTransitions {
            G(.a) | W(.h) | T(.b) | A(fail)
            G(.a) | W(.g) | T(.c) | A(pass)
        }
        fsm.handleEvent(.g)
        XCTAssertTrue(didPass)
        XCTAssertEqual(fsm.state, .c)
    }
    
    func testHandleUnsafeEvent() {
        let fsm = UnsafeFSM(initialState: State.a)
        fsm.buildTransitions {
            State.a | Event.h | State.b | fail
            State.a | Event.g | State.c | pass
        }
        fsm.handleEvent(Event.g)
        XCTAssertTrue(didPass)
        XCTAssertEqual(fsm.state, State.c.erased)
    }
}

class FSMPerformanceTests: SafeTests {
    var didPass = false
    func pass() {
        didPass = true
    }
    
    func fail() {
        XCTFail()
    }
    
    override func setUpWithError() throws {
        //throw XCTSkip("Skip performance tests")
    }
    
    func testBenchmarkBestCaseScenario() throws {
        func handleEvent(_ e: Event) {
            switch e { case .g: pass(); default: fail() }
        }
        
        measure { 250000.times { handleEvent(.g) } }
    }
    
    func testGenericPerformance() throws {
        let gFSM = FSM<State, Event>(initialState: .a)
        gFSM.buildTransitions { G(.a) | W(.g) | T(.c) | A(pass) }
        
        measure { 250000.times { gFSM.handleEvent(.g) } }
    }
    
    func testUnsafePerformance() throws {
        let usFSM = UnsafeFSM(initialState: State.a)
        usFSM.buildTransitions { State.a | Event.g | State.c | pass }
        
        measure { 250000.times { usFSM.handleEvent(Event.g) } }
    }
}

extension SafeTests.State: StateProtocol {}
extension SafeTests.Event: EventProtocol {}

extension Int {
    func times(_ block: @escaping () -> Void) {
        for _ in 1...self {
            block()
        }
    }
}
