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
    var calledActions: [String]!
    
    func action1() {
        calledActions.append("action1")
    }
    
    func action2() {
        calledActions.append("action2")
    }
    
    func fail() {
        XCTFail()
    }
    
    override func setUp() {
        calledActions = [String]()
    }
        
    func testThrowsErrorWhenGivenConflictingTransitions() {
        let fsm = FSMBase<State, Event>(initialState: .a)
        
        let file = URL(string: #file)!.lastPathComponent
        let l1 = #line + 5
        let l2 = #line + 5
        let l3 = #line + 5
        
        XCTAssertThrowsError (try fsm.buildTransitions {
            G(.a) | W(.h) | T(.b) | action1
            G(.a) | W(.h) | T(.c) | action2
            G(.a) | W(.h) | T(.d) | action2
        }) {
            let e = $0 as! ConflictingTransitionError
            XCTAssertEqual(e.localizedDescription.suffix(113),
"""
a | h | *b* (\(file): line \(l1))
a | h | *c* (\(file): line \(l2))
a | h | *d* (\(file): line \(l3))
"""
            )
            print(e.localizedDescription)
        }
    }
    
    func testHandlEvent() {
        let fsm = FSM<State, Event>(initialState: .a)
        try! fsm.buildTransitions {
            G(.a) | W(.h) | T(.b) | fail
            G(.a) | W(.g) | T(.c) | [action1, action2]
        }
        fsm.handleEvent(.g)
        XCTAssertEqual(calledActions, ["action1", "action2"])
        XCTAssertEqual(fsm.state, .c)
    }
    
    func testHandleUnsafeEvent() {
        let fsm = UnsafeFSM(initialState: State.a)
        try! fsm.buildTransitions {
            State.a | Event.h | State.b | fail
            State.a | Event.g | State.c | [action1, action2]
        }
        fsm.handleEvent(Event.g)
        XCTAssertEqual(calledActions, ["action1", "action2"])
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
        throw XCTSkip("Skip performance tests")
    }
    
    func testBenchmarkBestCaseScenario() throws {
        func handleEvent(_ e: Event) {
            switch e { case .g: pass(); default: fail() }
        }
        
        measure { 250000.times { handleEvent(.g) } }
    }
    
    func testGenericPerformance() throws {
        let fsm = FSM<State, Event>(initialState: .a)
        try! fsm.buildTransitions { G(.a) | W(.g) | T(.c) | pass }
        
        measure { 250000.times { fsm.handleEvent(.g) } }
    }
    
    func testUnsafePerformance() throws {
        let fsm = UnsafeFSM(initialState: State.a)
        try! fsm.buildTransitions { State.a | Event.g | State.c | pass }
        
        measure { 250000.times { fsm.handleEvent(Event.g) } }
    }
}

extension SafeTests.State: StateProtocol {}
extension SafeTests.Event: EventProtocol {}

extension Int {
    func times(_ block: @escaping () -> ()) {
        for _ in 1...self { block() }
    }
}
