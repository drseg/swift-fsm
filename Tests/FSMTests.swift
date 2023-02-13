////
////  FSMTests.swift
////  FiniteStateMachineTests
////
////  Created by Daniel Segall on 29/01/2023.
////
//
//import Foundation
//import XCTest
//@testable import FiniteStateMachine
//
//class FSMTests: XCTestCase, TransitionBuilder {
//    enum State: StateProtocol { case a, b, c, d, e, f, p, q, r, s, t, u, v, w }
//    enum Event: EventProtocol { case g, h, i, j, k, l, m, n, o }
//
//    typealias TR = TableRow<State, Event>
//
//    func testHandleUnsafeEvent() {
//        let fsm = AnyFSM(initialState: State.a)
//        try! fsm.buildTransitions {
//            State.a | Event.h | State.b | fail
//            State.a | Event.g | State.c | [action1, action2]
//        }
//        fsm.handleEvent(Event.g)
//        XCTAssertEqual(calledActions, ["action1", "action2"])
//        XCTAssertEqual(fsm.state, State.c.erase)
//    }
//
//    func assertThrows<E: Error>(
//        expected: E.Type,
//        building t: TableRow<AS, AE>
//    ) {
//        let fsm = AnyFSM(initialState: State.a)
//        XCTAssertThrowsError(
//            try fsm.buildTransitions { t }
//        ) { XCTAssert(type(of: $0) == expected) }
//    }
//
//    func testThrowsErrorIfGivenNSObject() {
//        assertThrows(expected: NSObjectError.self,
//                     building: NSObject() | Event.h | State.b | fail)
//        assertThrows(expected: NSObjectError.self,
//                     building: State.a | NSObject() | State.b | fail)
//        assertThrows(expected: NSObjectError.self,
//                     building: State.a | Event.h | NSObject() | fail)
//    }
//
//    func testThrowsErrorIfStateTypesDoNotMatch() {
//        assertThrows(expected: MismatchedType.self,
//                     building: "Cat" | Event.h | 2 | fail)
//    }
//}

//class FSMPerformanceTests: SafeTests {
//    var didPass = false
//    func pass() {
//        didPass = true
//    }
//
//    func fail() {
//        XCTFail()
//    }
//
//    override func setUpWithError() throws {
//        throw XCTSkip("Skip performance tests")
//    }
//
//    func testBenchmarkBestCaseScenario() throws {
//        func handleEvent(_ e: Event) {
//            if (true) {
//                if (true) {
//                    if (true) {
//                        switch e { case .g: pass(); default: fail() }
//                    }
//                }
//            }
//        }
//
//        measure { 250000.times { handleEvent(.g) } }
//    }
//
//    func testGenericPerformance() throws {
//        let fsm = FSM<State, Event>(initialState: .a)
//        try! fsm.buildTransitions { G(.a) | W(.g) | T(.c) | pass }
//
//        measure { 250000.times { fsm.handleEvent(.g) } }
//    }
//
//    func testUnsafePerformance() throws {
//        let fsm = AnyFSM(initialState: State.a)
//        try! fsm.buildTransitions { State.a | Event.g | State.c | pass }
//
//        measure { 250000.times { fsm.handleEvent(Event.g) } }
//    }
//}
//
//extension Int {
//    func times(_ block: @escaping () -> ()) {
//        for _ in 1...self { block() }
//    }
//}
