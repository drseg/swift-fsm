//
//  SafeTests.swift
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class SafeTests: XCTestCase {
    enum State: StateProtocol { case a, b, c, d, e, f, p, q, r, s, t, u, v, w }
    enum Event: EventProtocol { case g, h, i, j, k, l }

    typealias G = Given<State, Event>
    typealias W = When<Event>
    typealias T = Then<State>

    typealias TR = TableRow<State, Event>

    func transition(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ actions: [() -> ()] = []
    ) -> Transition<State, Event> {
        Transition(givenState: given,
                   event: when,
                   nextState: then,
                   actions: actions)
    }

    func assertContains(
        _ sess: [(State, Event, State)],
        _ tr: TR,
        line: UInt = #line
    ) {
        assertContains(sess, tr.transitions, line: line)
    }

    func assertContains(
        _ sess: [(State, Event, State)],
        _ tr: [Transition<State, Event>],
        line: UInt = #line
    ) {
        sess.forEach {
            assertContains($0.0, $0.1, $0.2, tr, line: line)
        }
    }

    func assertContains(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ tr: TR,
        line: UInt = #line
    ) {
        assertContains(given, when, then, tr.transitions, line: line)
    }

    func assertContains(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ tr: [Transition<State, Event>],
        line: UInt = #line
    ) {
        XCTAssertTrue(tr.contains(where: {
            $0.givenState == given &&
            $0.event == when &&
            $0.nextState == then
        }), line: line)
    }

    func assertCount(
        _ expected: Int,
        _ tr: TR,
        line: UInt = #line
    ) {
        assertCount(expected, tr.transitions, line: line)
    }

    func assertCount(
        _ expected: Int,
        _ tr: [Transition<State, Event>],
        line: UInt = #line
    ) {
        XCTAssertEqual(tr.count, expected, line: line)
    }

    func doNothing() {}
}

final class SafeTransitionTests: SafeTests {
    func testSimpleConstructor() {
        let tr = G(.a) | W(.g) | T(.b) | { }

        assertContains(.a, .g, .b, tr)
    }

    func testMultiGivenConstructor() {
        let tr = G(.a, .b) | W(.g) | T(.b) | { }
        
        assertContains(.a, .g, .b, tr)
        assertContains(.b, .g, .b, tr)
        assertCount(2, tr)
    }
    
    func testMultiGivenConstructorWithDuplicates() {
        let tr = G(.a, .b, .b) | W(.g) | T(.b) | { }
        
        assertContains(.a, .g, .b, tr)
        assertContains(.b, .g, .b, tr)
        assertCount(2, tr)
    }
    
    func testMultiActionConstructor() {
        let _ = G(.a) | W(.g) | T(.b) | [{ }, { }]
        // nothing to assert here, just needs to compile
    }
    
    func testMultiWhenThenActionConstructor() {
        let tr = G(.a) | [W(.g) | T(.b) | { },
                          W(.h) | T(.c) | { }]
        
        assertContains(.a, .g, .b, tr)
        assertContains(.a, .h, .c, tr)
        assertCount(2, tr)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        let tr = G(.a, .b) | [W(.g) | T(.c) | { },
                              W(.h) | T(.c) | { }]
        
        assertContains(.a, .g, .c, tr)
        assertContains(.b, .h, .c, tr)
        assertCount(4, tr)
    }
    
    func testMultiWhenConstructor() {
        let tr = G(.a) | W(.g, .h) | T(.c) | { }
        
        assertContains(.a, .g, .c, tr)
        assertContains(.a, .h, .c, tr)
        assertCount(2, tr)
    }
    
    func testMultiWhenConstructorWithDuplicates() {
        let tr = G(.a) | W(.g, .h, .h) | T(.c) | { }
        
        assertContains(.a, .g, .c, tr)
        assertContains(.a, .h, .c, tr)
        assertCount(2, tr)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        let tr = G(.a, .b) | W(.g, .h) | T(.c) | { }
        
        assertContains(.a, .g, .c, tr)
        assertContains(.b, .h, .c, tr)
        assertCount(4, tr)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        let tr = G(.a, .b) | [
            W(.g, .h) | T(.c) | { },
            W(.i, .j) | T(.d) | { }
        ]
        
        assertContains(.a, .g, .c, tr)
        assertContains(.b, .j, .d, tr)
        assertCount(8, tr)
    }
    
    func testMultiWhenThenConstructor() {
        let tr = G(.a) | [W(.g) | T(.c),
                          W(.h) | T(.d)] | { }
        
        assertContains(.a, .g, .c, tr)
        assertContains(.a, .h, .d, tr)
        assertCount(2, tr)
    }
    
    func testMaxConstructors() {
        let tr = G(.a, .b) | [[W(.g, .h) | T(.c),
                               W(.h, .i) | T(.d)] | { },
                              
                              [W(.i, .j) | T(.e),
                               W(.j, .k) | T(.f)] | { }]
        
        assertContains(.a, .g, .c, tr)
        assertContains(.b, .k, .f, tr)
        assertCount(16, tr)
    }
    
    func testEquality() {
        let x = G(.a, .b) | W(.g) | T(.c) | { }
        var y = G(.a, .b) | W(.g) | T(.c) | { }
        XCTAssertEqual(Set(x.transitions), Set(y.transitions))
        
        y =     G(.a, .b) | W(.h) | T(.c) | { }
        XCTAssertNotEqual(x.transitions, y.transitions)
        y =     G(.a, .b) | W(.g) | T(.b) | { }
        XCTAssertNotEqual(x.transitions, y.transitions)
    }
    
    func testTableBuilder() {
        let tr = build {
            G(.a, .b) | W(.g) | T(.c) | { }
            G(.c)     | W(.h) | T(.d) | { }
            G(.d)     | W(.i) | T(.e) | { }
            G(.e)     | W(.j) | T(.f) | { }
        }
        
        assertCount(5,  tr)
    }
    
    func testGivenBuilder() {
        let tr = G(.a, .b) {
            W(.h) | T(.b) | { }
            W(.g) | T(.a) | { }
        }
        
        assertContains(.a, .h, .b, tr)
        assertContains(.b, .g, .a, tr)
        assertCount(4, tr)
    }
    
    func testGivenBuilderWithWhenThenArray() {
        let tr = G(.a, .b) {
            [W(.h) | T(.b),
             W(.g) | T(.a)] | { }
        }
        
        assertContains(.a, .h, .b, tr)
        assertContains(.b, .g, .a, tr)
        assertCount(4, tr)
    }
    
    func testActionModifier() {
        let e = expectation(description: "call action")
        
        let tr =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.action { e.fulfill() }
        
        assertContains(.a, .h, .b, tr)
        assertContains(.b, .g, .a, tr)
        assertCount(4, tr)
        
        tr.transitions.first?.actions.first?()
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionsModifier() {
        let e = expectation(description: "call action")
        e.expectedFulfillmentCount = 2
        
        let tr =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.actions(e.fulfill, e.fulfill)
        
        assertContains(.a, .h, .b, tr)
        assertContains(.b, .g, .a, tr)
        assertCount(4, tr)
        
        tr.transitions.first?.actions.forEach { $0() }
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionsPassedCorrectly() {
        let e = expectation(description: "passAction")
        e.expectedFulfillmentCount = 2
        let tr = G(.a) | W(.g) | T(.c) | [e.fulfill, e.fulfill]
        tr.transitions.first?.actions.forEach { $0() }
        waitForExpectations(timeout: 0.1)
    }
    
    func testBuilderIfTrue() {
        let condition = true
        let trc = build {
            if condition {
                G(.a) | W(.g) | T(.b) | { }
            }
        }
        
        XCTAssertEqual(trc.first, transition(.a, .g, .b))
    }
    
    func testBuilderIfFalse() {
        let condition = false
        let trc = build {
            if condition {
                G(.a) | W(.g) | T(.b) | { }
            }
        }
        XCTAssert(trc.isEmpty)
    }
    
    func testBuilderElse() {
        let test = false
        let trc = build {
            if test {
                G(.a) | W(.g) | T(.b) | { }
                G(.a) | W(.h) | T(.b) | { }
            } else {
                G(.b) | W(.i) | T(.b) | { }
            }
        }
        
        assertCount(1, trc)
        XCTAssertEqual(trc.first, transition(.b, .i, .b))
    }
    
    func testBuilderSwitch() {
        enum Switchy { case on, off }
        
        let state = Switchy.on
        let trc = build {
            switch state {
            case .on:  G(.a) | W(.g) | T(.b) | { }
            case .off: G(.b) | W(.i) | T(.b) | { }
            }
        }
        XCTAssertEqual(trc.first, transition(.a, .g, .b))
    }
}

class SuperStateTransitionTests: SafeTests {
    typealias TS = [Transition<State, Event>]
    
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
        func assertOutput(_ t: [Transition<State, Event>]..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s)], $0, line: line)
                assertCount(2, $0, line: line)
            }
        }

        let tr1 = build { G(.a).include(s1) { W(.g) | T(.s) | { } } }
        let tr2 = build { G(.a).include(s1) | W(.g) | T(.s) | { } }

        let tr3 = build { G(.a).include(ss) }
        let tr4 = build { G(.a).include(s1, s2) }
        let tr5 = build { G(.a).include(s1).include(s2) }
        
        assertOutput(tr1, tr2, tr3, tr4, tr5)
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
                                (.a, .h, .s)], $0, line: line)
                assertCount(3, $0, line: line)
            }
        }
        
        let tr1 = build {
            G(.a).include(s1) {
                W(.g) | T(.s) | { }
                W(.h) | T(.s) | { }
            }
        }
        let tr2 = build {
            G(.a).include(s1) | [W(.g) | T(.s) | { },
                                 W(.h) | T(.s) | { }] }
        
        let tr3 = build {
            G(.a).include(ss) | [W(.h) | T(.s) | { }]
        }
        
        let tr4 = build {
            G(.a).include(s1, s2) | [W(.h) | T(.s) | { }]
        }
        
        let tr5 = build {
            G(.a).include(ss) { W(.h)  | T(.s)  | { } }
        }
        
        let tr6 = build {
            G(.a).include(s1, s2) { W(.h)  | T(.s) | { } }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWTA() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .h, .s)], $0, line: line)
                assertCount(6, $0, line: line)
            }
        }
        
        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g) | T(.s) | { }
                W(.h) | T(.s) | { }
            }
        }
        
        let tr2 = build {
            G(.a, .b).include(s1) | [W(.g) | T(.s) | { },
                                     W(.h) | T(.s) | { }]
        }
        
        let tr3 = build {
            G(.a, .b).include(ss) | [W(.h) | T(.s) | { }]
        }
        
        let tr4 = build {
            G(.a, .b).include(s1, s2) | [W(.h) | T(.s) | { }]
        }

        assertOutput(tr1, tr2, tr3, tr4)
    }

    func testMultitipleWhen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.a, .i, .s)], $0, line: line)
                assertCount(4, $0, line: line)
            }
        }

        let tr1 = build { G(.a).include(s1) {
            W(.g, .h, .i) | T(.s) | { }
        } }
        let tr2 = build {
            G(.a).include(s1)     | W(.g, .h, .i) | T(.s) | { } }
        let tr3 = build {
            G(.a).include(s1, s2) | W(.h, .i)     | T(.s) | { } }
        let tr4 = build {
            G(.a).include(ss)     | W(.h, .i)     | T(.s) | { } }
        let tr5 = build {
            G(.a).include(s1, s2) { W(.h, .i)     | T(.s) | { } } }
        let tr6 = build {
            G(.a).include(ss)     { W(.h, .i)     | T(.s) | { } } }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWhen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.a, .i, .s),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .h, .s),
                                (.b, .i, .s)], $0, line: line)
                assertCount(8, $0, line: line)
            }
        }
        
        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g, .h, .i) | T(.s) | { }
            } }
        let tr2 = build {
            G(.a, .b).include(s1)     | W(.g, .h, .i) | T(.s) | { } }
        let tr3 = build {
            G(.a, .b).include(s1, s2) | W(.h, .i)     | T(.s) | { } }
        let tr4 = build {
            G(.a, .b).include(ss)     | W(.h, .i)     | T(.s) | { } }
        let tr5 = build {
            G(.a, .b).include(s1, s2) { W(.h, .i)     | T(.s) | { } } }
        let tr6 = build {
            G(.a, .b).include(ss)     { W(.h, .i)     | T(.s) | { } } }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleGivenMultipleWhenMultipleThenAction() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.a, .i, .d),
                                (.a, .j, .d),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .h, .s),
                                (.b, .i, .d),
                                (.b, .j, .d)], $0, line: line)
                assertCount(10, $0, line: line)
            }
        }
        
        let tr1 = build {
            G(.a, .b).include(s1) {
                W(.g, .h) | T(.s) | { }
                W(.i, .j) | T(.d) | { }
            }
        }
        
        let tr2 = build {
            G(.a, .b).include(s1) | [W(.g, .h) | T(.s) | { },
                                     W(.i, .j) | T(.d) | { }]
        }
        
        let tr3 = build {
            G(.a, .b).include(s1, s2) | [W(.h)     | T(.s) | { },
                                         W(.i, .j) | T(.d) | { }]
        }
        
        let tr4 = build {
            G(.a, .b).include(ss) | [W(.h) | T(.s) | { },
                                     W(.i, .j) | T(.d) | { }]
        }
        
        let tr5 = build {
            G(.a, .b).include(s1, s2) {
                W(.h)     | T(.s) | { }
                W(.i, .j) | T(.d) | { }
            }
        }
        
        let tr6 = build {
            G(.a, .b).include(ss) {
                W(.h)     | T(.s) | { }
                W(.i, .j) | T(.d) | { }
            }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testMultipleWhenThen() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.a, .i, .s)], $0, line: line)
                assertCount(4, $0)
            }
        }
        
        let tr1 = build {
            G(.a).include(s1) {
                [W(.g) | T(.s),
                 W(.h) | T(.s),
                 W(.i) | T(.s)] | { }
            }
        }
        
        let tr2 = build {
            G(.a).include(s1) | [W(.g) | T(.s),
                                 W(.h) | T(.s),
                                 W(.i) | T(.s)] | { }
        }
        
        let tr3 = build {
            G(.a).include(s1, s2) | [W(.h) | T(.s),
                                     W(.i) | T(.s)] | { }
        }
        
        let tr4 = build {
            G(.a).include(ss) | [W(.h) | T(.s),
                                 W(.i) | T(.s)] | { }
        }
        
        let tr5 = build {
            G(.a).include(ss) {
                W(.h) | T(.s)
                W(.i) | T(.s) }.action { }
        }
        
        let tr6 = build {
            G(.a).include(s1, s2) {
                W(.h) | T(.s)
                W(.i) | T(.s) }.action { }
        }

        assertOutput(tr1, tr2, tr3, tr4, tr5, tr6)
    }

    func testAll() {
        func assertOutput(_ t: TS..., line: UInt = #line) {
            t.forEach {
                assertContains([(.a, .h, .b),
                                (.a, .g, .s),
                                (.a, .h, .s),
                                (.a, .h, .t),
                                (.a, .i, .t),
                                (.a, .i, .s),
                                (.a, .j, .s),
                                (.a, .j, .t),
                                (.a, .k, .t),
                                (.b, .h, .b),
                                (.b, .g, .s),
                                (.b, .h, .s),
                                (.b, .h, .t),
                                (.b, .i, .t),
                                (.b, .i, .s),
                                (.b, .j, .s),
                                (.b, .j, .t),
                                (.b, .k, .t)], $0, line: line)
                
                assertCount(18, $0, line: line)
            }
        }
        
        let tr1 = build {
            G(.a, .b).include(s1) {
                [W(.g, .h) | T(.s),
                 W(.h, .i) | T(.t)] | { }
                
                [W(.i, .j) | T(.s),
                 W(.j, .k) | T(.t)] | { }
            }
        }
        
        let tr2 = build {
            G(.a, .b).include(s1) | [[W(.g, .h) | T(.s),
                                      W(.h, .i) | T(.t)] | { },
                                     
                                     [W(.i, .j) | T(.s),
                                      W(.j, .k) | T(.t)] | { }]
        }
        
        let tr3 = build {
            G(.a, .b).include(s1, s2) | [[W(.h)     | T(.s),
                                          W(.h, .i) | T(.t)] | { },
                                         
                                         [W(.i, .j) | T(.s),
                                          W(.j, .k) | T(.t)] | { }]
        }
        
        let tr4 = build {
            G(.a, .b).include(ss) | [[W(.h)     | T(.s),
                                      W(.h, .i) | T(.t)] | { },
                                     
                                     [W(.i, .j) | T(.s),
                                      W(.j, .k) | T(.t)] | { }]
        }
        
        let tr5 = build {
            G(.a, .b).include(s1, s2) {
                [W(.h)     | T(.s),
                 W(.h, .i) | T(.t)] | { }
                
                [W(.i, .j) | T(.s),
                 W(.j, .k) | T(.t)] | { }
            }
        }
        
        let tr6 = build {
            G(.a, .b).include(ss) {
                [W(.h)     | T(.s),
                 W(.h, .i) | T(.t)] | { }
                
                [W(.i, .j) | T(.s),
                 W(.j, .k) | T(.t)] | { }
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

class DemonstrationTests: SafeTests {
    typealias W = When<String>; typealias T = Then<String>
    
    func alarmOff() {}; func unlock() {}; func alarmOn() {}
    func thankyou() {}; func lock() {}
    
    func testCompilation() {
        let _ = build {
            let resetable = SuperState {
                W("Reset") | T("Locked")  | [alarmOff, lock]
            }
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
            
            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }
        }
    }
    
    func testTurnstile() {
    /*
     Initial: Locked
     FSM: Turnstile {
        (Resetable)  {
            Reset       Locked       {alarmOff lock}
        } // This is an abstract super state.

        Locked : Resetable    {
             Coin    Unlocked    unlock
             Pass    Alarming    alarmOn
        }

        Unlocked : Resetable {
             Coin    Unlocked    thankyou
             Pass    Locked      lock
         }

        Alarming : Resetable { // inherits all its transitions from Resetable }
     }
     */
        let fsm = FSM<String, String>(initialState: "Locked")
        try! fsm.buildTransitions {
            let resetable = SuperState {
                W("Reset") | T("Locked")  | [alarmOff, lock]
            }

            Given("Locked").include(resetable) {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }

            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }

            Given("Alarming").include(resetable)
        }

        /*
         Initial: Locked
         FSM: Turnstile
         {
           (Resetable) {
             Reset       Locked       -
           }
           Locked : Resetable <lock     {
             Coin    Unlocked    -
             Pass    Alarming    -
           }
           Unlocked : Resetable <unlock  {
             Coin    Unlocked    thankyou
             Pass    Locked      -
           }
           Alarming : Resetable <alarmOn >alarmOff   -    -    -
         }

         Given("Locked")
            .include(resetable)
            .onEnter(soSomething) // StateEvent held by Given
            .onLeave(doSomethingElse) // StateEvent held by Given
         {
             W("Coin") | T("Unlocked") | unlock
             W("Pass") | T("Alarming") | alarmOn
             // change from [Transition] to FSMTableRow(entryActions, exitActions, transitions)
         }

         */
    }
}
