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
        let fsm = AnyFSM(initialState: State.a)
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
        building t: TableRow<AS, AE>
    ) {
        let fsm = AnyFSM(initialState: State.a)
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

class SuperStateTransitionTests: SafeTests {
    typealias TS = [Transition<State, Event>]
    
    var fsm: FSM<State, Event>!
    
    class NoThrowFSM<S: SP, E: EP>: FSM<S, E> {
        override func throwError(_ e: Error) throws { }
    }
    
    override func setUp() {
        fsm = NoThrowFSM<State, Event>(initialState: .a)
    }
    
    func build(
        @TableBuilder<State, Event> _ ts: () -> [any TableRowProtocol<State, Event>]
    ) ->  TS {
        try! fsm.buildTransitions(ts)
        return Array(fsm.transitions.values)
    }
    
    func testBuilder() {
        func wta(
            _ when: Event, _ then: State
        ) -> WhenThenAction<State, Event> {
            WhenThenAction(when: when,
                           then: then,
                           actions: [])
        }

        let s = SuperState {
            W(.h) | T(.b) | { }
            W(.g) | T(.s) | { }
        }

        XCTAssertEqual(s.wtas.first!, wta(.h, .b))
        XCTAssertEqual(s.wtas.last!, wta(.g, .s))
    }

    let s1 = SuperState { W(.h) | T(.b) | { } }
    let s2 = SuperState { W(.g) | T(.s) | { } }
    let ss = SuperState {
        W(.h) | T(.b) | { }
        W(.g) | T(.s) | { }
    }

    func testGiven() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s)], $0, line: line)
                assertCount(2, $0, line: line)
            }
        }

        let tr1 = build   { G(.a).include(s1) { W(.g) | T(.s) | { } } }
        let tr2 = build   { G(.a).include(s1) | W(.g) | T(.s) | { } }

        let tr3 = build   { G(.a).include(ss) }
        let tr4 = build   { G(.a).include(s1, s2) }
        let tr5 = build   { G(.a).include(s1).include(s2) }

        let tr6 = build   {(G(.a) => s1){ W(.g) | T(.s) | { } } }
        let tr7 = build   { G(.a) => s1 | W(.g) | T(.s) | { } }

        let tr8 = build   { G(.a) => ss }
        let tr9 = build   { G(.a) => [s1, s2] }
        let tr10 = build  { G(.a) => s1 => s2 }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6, tr7, tr8, tr9, tr10)
    }

    func testMultipleGiven() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.b, .h, .b),
                                (.b, .g, .s)], $0, line: line)
                assertCount(4, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a, .b).include(s1) { W(.g) | T(.s) | { } } }
        let tr2 = build {
            G(.a, .b).include(s1) | W(.g) | T(.s) | { } }

        let tr3 = build { G(.a, .b).include(ss) }
        let tr4 = build { G(.a, .b).include(s1, s2) }

        assertOutput(tr1, tr2, tr3, tr4)
    }

    func testMultipleWhenThenAction() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .i, .s)], $0, line: line)
                assertCount(3, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a).include(s1) {
                W(.g) | T(.s) | { }
                W(.i) | T(.s) | { }
            }
        }
        let tr2 = build {
            G(.a).include(s1) | [W(.g) | T(.s) | { },
                                 W(.i) | T(.s) | { }] }

        let tr3 = build {
            G(.a).include(ss) | [W(.i) | T(.s) | { }]
        }

        let tr4 = build {
            G(.a).include(s1, s2) | [W(.i) | T(.s) | { }]
        }

        let tr5 = build {
            G(.a).include(ss) { W(.i)  | T(.s)  | { } }
        }

        let tr6 = build {
            G(.a).include(s1, s2) { W(.i)  | T(.s) | { } }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWTA() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .i, .s),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .i, .s)], $0, line: line)
                assertCount(6, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g) | T(.s) | { }
                W(.i) | T(.s) | { }
            }
        }

        let tr2 = build {
            G(.a, .b).include(s1) | [W(.g) | T(.s) | { },
                                     W(.i) | T(.s) | { }]
        }

        let tr3 = build {
            G(.a, .b).include(ss) | [W(.i) | T(.s) | { }]
        }

        let tr4 = build {
            G(.a, .b).include(s1, s2) | [W(.i) | T(.s) | { }]
        }

        assertOutput(tr1, tr2, tr3, tr4)
    }

    func testMultitipleWhen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .i, .s),
                                (.a, .j, .s)], $0, line: line)
                assertCount(4, $0, line: line)
            }
        }

        let tr1 = build { G(.a).include(s1) {
            W(.g, .i, .j) | T(.s) | { }
        } }
        let tr2 = build {
            G(.a).include(s1)     | W(.g, .i, .j) | T(.s) | { } }
        let tr3 = build {
            G(.a).include(s1, s2) | W(.i, .j)     | T(.s) | { } }
        let tr4 = build {
            G(.a).include(ss)     | W(.i, .j)     | T(.s) | { } }
        let tr5 = build {
            G(.a).include(s1, s2) { W(.i, .j)     | T(.s) | { } } }
        let tr6 = build {
            G(.a).include(ss)     { W(.i, .j)     | T(.s) | { } } }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWhen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .i, .s),
                                (.a, .j, .s),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .i, .s),
                                (.b, .j, .s)], $0, line: line)
                assertCount(8, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g, .i, .j) | T(.s) | { }
            } }
        let tr2 = build {
            G(.a, .b).include(s1)     | W(.g, .i, .j) | T(.s) | { } }
        let tr3 = build {
            G(.a, .b).include(s1, s2) | W(.i, .j)     | T(.s) | { } }
        let tr4 = build {
            G(.a, .b).include(ss)     | W(.i, .j)     | T(.s) | { } }
        let tr5 = build {
            G(.a, .b).include(s1, s2) { W(.i, .j)     | T(.s) | { } } }
        let tr6 = build {
            G(.a, .b).include(ss)     { W(.i, .j)     | T(.s) | { } } }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWhenMultipleThenAction() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                
                                (.a, .g, .s),
                                (.a, .i, .s),
                                (.a, .j, .d),
                                (.a, .k, .d),
                                
                                (.b, .h, .b),
                                
                                (.b, .g, .s),
                                (.b, .i, .s),
                                (.b, .j, .d),
                                (.b, .k, .d)], $0, line: line)
                assertCount(10, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g, .i) | T(.s) | { }
                W(.j, .k) | T(.d) | { }
            }
        }

        let tr2 = build {
            G(.a, .b).include(s1) | [W(.g, .i) | T(.s) | { },
                                     W(.j, .k) | T(.d) | { }]
        }

        let tr3 = build {
            G(.a, .b).include(s1, s2) | [W(.g, .i) | T(.s) | { },
                                         W(.j, .k) | T(.d) | { }]
        }

        let tr4 = build {
            G(.a, .b).include(ss) | [W(.g, .i) | T(.s) | { },
                                     W(.j, .k) | T(.d) | { }]
        }

        let tr5 = build {
            G(.a, .b).include(s1, s2) {
                W(.i)     | T(.s) | { }
                W(.j, .k) | T(.d) | { }
            }
        }

        let tr6 = build {
            G(.a, .b).include(ss) {
                W(.i)     | T(.s) | { }
                W(.j, .k) | T(.d) | { }
            }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleWhenThen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .i, .s),
                                (.a, .j, .s)], $0, line: line)
                assertCount(4, $0)
            }
        }

        let tr1 = build {
            G(.a).include(s1) {
                [W(.g) | T(.s),
                 W(.i) | T(.s),
                 W(.j) | T(.s)] | { }
            }
        }

        let tr2 = build {
            G(.a).include(s1) | [W(.g) | T(.s),
                                 W(.i) | T(.s),
                                 W(.j) | T(.s)] | { }
        }

        let tr3 = build {
            G(.a).include(s1, s2) | [W(.i) | T(.s),
                                     W(.j) | T(.s)] | { }
        }

        let tr4 = build {
            G(.a).include(ss) | [W(.i) | T(.s),
                                 W(.j) | T(.s)] | { }
        }

        let tr5 = build {
            G(.a).include(ss) {
                W(.i) | T(.s)
                W(.j) | T(.s) }.action { }
        }

        let tr6 = build {
            G(.a).include(s1, s2) {
                W(.i) | T(.s)
                W(.j) | T(.s) }.action { }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testAll() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                
                                (.a, .g, .s),
                                (.a, .i, .s),
                                
                                (.a, .j, .t),
                                (.a, .k, .t),
                            
                                (.a, .l, .s),
                                (.a, .m, .s),
                                
                                (.a, .n, .t),
                                (.a, .o, .t),
                                
                                (.b, .h, .b),
                                
                                (.b, .g, .s),
                                (.b, .i, .s),
                                
                                (.b, .j, .t),
                                (.b, .k, .t),
                                
                                (.b, .l, .s),
                                (.b, .m, .s),
                                
                                (.b, .n, .t),
                                (.b, .o, .t)], $0, line: line)

                assertCount(18, $0, line: line)
            }
        }

        let tr1 = build {
            G(.a, .b).include(s1) {
                [W(.g, .i) | T(.s),
                 W(.j, .k) | T(.t)] | { }

                [W(.l, .m) | T(.s),
                 W(.n, .o) | T(.t)] | { }
            }
        }

        let tr2 = build {
            G(.a, .b).include(s1) | [[W(.g, .i) | T(.s),
                                      W(.j, .k) | T(.t)] | { },

                                     [W(.l, .m) | T(.s),
                                      W(.n, .o) | T(.t)] | { }]
        }

        let tr3 = build {
            G(.a, .b).include(s1, s2) | [[W(.g, .i) | T(.s),
                                          W(.j, .k) | T(.t)] | { },

                                         [W(.l, .m) | T(.s),
                                          W(.n, .o) | T(.t)] | { }]
        }

        let tr4 = build {
            G(.a, .b).include(ss) | [[W(.g, .i) | T(.s),
                                      W(.j, .k) | T(.t)] | { },

                                     [W(.l, .m) | T(.s),
                                      W(.n, .o) | T(.t)] | { }]
        }

        let tr5 = build {
            G(.a, .b).include(s1, s2) {
                [W(.g, .i) | T(.s),
                 W(.j, .k) | T(.t)] | { }

                [W(.l, .m) | T(.s),
                 W(.n, .o) | T(.t)] | { }
            }
        }

        let tr6 = build {
            G(.a, .b).include(ss) {
                [W(.g, .i) | T(.s),
                 W(.j, .k) | T(.t)] | { }

                [W(.l, .m) | T(.s),
                 W(.n, .o) | T(.t)] | { }
            }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }
}

class FileLineTests: SafeTests {
    func testFileAndLine() {
        let file: String = String(#file)

        let l1 = #line; let tr1 = G(.a) {
            W(.g) | T(.s) | { }
        }
        let l2 = #line; let tr2 = G(.a) | W(.g) | T(.s) | { }

        XCTAssertEqual(tr1.transitions.first?.line, l1)
        XCTAssertEqual(tr2.transitions.first?.line, l2)

        XCTAssertEqual(tr1.transitions.first?.file, file)
        XCTAssertEqual(tr2.transitions.first?.file, file)
    }
#warning("the file/line should be sourced from the 'Then' not the 'Given'")
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
        let fsm = AnyFSM(initialState: State.a)
        try! fsm.buildTransitions { State.a | Event.g | State.c | pass }
        
        measure { 250000.times { fsm.handleEvent(Event.g) } }
    }
}

extension Int {
    func times(_ block: @escaping () -> ()) {
        for _ in 1...self { block() }
    }
}
