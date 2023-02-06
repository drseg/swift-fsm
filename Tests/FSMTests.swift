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
        
    func testThrowsErrorWhenGivenDuplicates() {
        let fsm = FSMBase<State, Event>(initialState: .a)
        
        let file = URL(string: #file)!.lastPathComponent
        let l1 = #line + 6
        let l2 = #line + 6
        let l3 = #line + 6
        let l4 = #line + 6
        
        XCTAssertThrowsError (try fsm.buildTransitions {
            G(.a) | W(.h) | T(.b) | action1
            G(.a) | W(.h) | T(.b) | action2
            G(.a) | W(.h) | T(.d) | action2
            G(.a) | W(.h) | T(.d) | action1
        }) {
            let e = $0 as! DuplicateTransitions<State, Event>
            XCTAssertEqual(e.description.split(separator: ":\n",
                                               maxSplits: 1).last!,
"""
a | h | *b* (\(file): \(l1))
a | h | *b* (\(file): \(l2))
a | h | *d* (\(file): \(l3))
a | h | *d* (\(file): \(l4))
"""
            )
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
        XCTAssertEqual(fsm.state, State.c.erase)
    }
    
    func assertThrows<E: Error>(
        expected: E.Type,
        building t: [Transition<AS, AE>]
    ) {
        let fsm = UnsafeFSM(initialState: State.a)
        XCTAssertThrowsError(
            try fsm.buildTransitions { t }
        ) { XCTAssert(type(of: $0) == expected) }
    }
    
    func testThrowsErrorIfGivenNSObject() {
        assertThrows(expected: NSObjectError.self,
                     building: NSObject() | Event.h | State.b | fail)
        assertThrows(expected: NSObjectError.self,
                     building: State.a | NSObject() | State.b | fail)
        assertThrows(expected: NSObjectError.self,
                     building: State.a | Event.h | NSObject() | fail)
    }
    
    func testThrowsErrorIfStateTypesDoNotMatch() {
        assertThrows(expected: MismatchedType.self,
                     building: "Cat" | Event.h | 2 | fail)
    }
}

extension NSObject: StateProtocol {}
extension NSObject: EventProtocol {}

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
            if (true) {
                if (true) {
                    if (true) {
                        switch e { case .g: pass(); default: fail() }
                    }
                }
            }
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
