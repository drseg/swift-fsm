//
//  SittingFSMTests.swift
//  SittingTests
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class SafeTests: XCTestCase {
    enum State { case a, b, c, d, e, f, p, q, r, s, t, u, v, w }
    enum Event { case g, h, i, j, k, l }
    
    typealias G = Given<State, Event>
    typealias W = When<Event>
    typealias T = Then<State>
    
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
    
    
    func assertFirst(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ t: [Transition<State, Event>],
        line: UInt = #line
    ) {
        assert(i: 0, given, when, then, t)
    }
    
    func assertLast(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ t: [Transition<State, Event>],
        line: UInt = #line
    ) {
        assert(i: t.count - 1, given, when, then, t)
    }
    
    func assert(
        i: Int,
        _ given: State,
        _ when: Event,
        _ then: State,
        _ t: [Transition<State, Event>],
        line: UInt = #line
    ) {
        XCTAssertEqual(t[i], transition(given, when, then), line: line)
    }
    
    func assertCount(
        _ expected: Int,
        _ t: [Transition<State, Event>],
        line: UInt = #line) {
        XCTAssertEqual(t.count, expected, line: line)
    }
    
    func doNothing() {}
}

final class SafeTransitionTests: SafeTests {
    func testSimpleConstructor() {
        let t = G(.a) | W(.g) | T(.b) | { }
        
        assertFirst(.a, .g, .b, t)
    }
    
    func testMultiGivenConstructor() {
        let t = G(.a, .b) | W(.g) | T(.b) | { }
        
        assertFirst(.a, .g, .b, t)
        assertLast(.b, .g, .b, t)
        assertCount(2, t)
    }
    
    func testMultiActionConstructor() {
        let _ = G(.a) | W(.g) | T(.b) | [{ }, { }]
        // nothing to assert here, just needs to compile
    }
    
    func testMultiWhenThenActionConstructor() {
        let t = G(.a) | [W(.g) | T(.b) | { },
                         W(.h) | T(.c) | { }]
        
        assertFirst(.a, .g, .b, t)
        assertLast(.a, .h, .c, t)
        assertCount(2, t)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        let t = G(.a, .b) | [W(.g) | T(.c) | { },
                             W(.h) | T(.c) | { }]
        
        assertFirst(.a, .g, .c, t)
        assertLast(.b, .h, .c, t)
        assertCount(4, t)
    }
    
    func testMultiWhenConstructor() {
        let t = G(.a) | W(.g, .h) | T(.c) | { }
        
        assertFirst(.a, .g, .c, t)
        assertLast(.a, .h, .c, t)
        assertCount(2, t)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        let t = G(.a, .b) | W(.g, .h) | T(.c) | { }
        
        assertFirst(.a, .g, .c, t)
        assertLast(.b, .h, .c, t)
        assertCount(4, t)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        let t = G(.a, .b) | [
            W(.g, .h) | T(.c) | { },
            W(.i, .j) | T(.d) | { }
        ]
        
        assertFirst(.a, .g, .c, t)
        assertLast(.b, .j, .d, t)
        assertCount(8, t)
    }
    
    func testMultiWhenThenConstructor() {
        let t = G(.a) | [W(.g) | T(.c),
                         W(.h) | T(.d)] | { }
        
        assertFirst(.a, .g, .c, t)
        assertLast(.a, .h, .d, t)
        assertCount(2, t)
    }
    
    func testMaxConstructors() {
        let t = G(.a, .b) | [[W(.g, .h) | T(.c),
                              W(.h, .i) | T(.d)] | { },
                             
                             [W(.i, .j) | T(.e),
                              W(.j, .k) | T(.f)] | { }]
        
        assertFirst(.a, .g, .c, t)
        assertLast(.b, .k, .f, t)
        assertCount(16, t)
    }
    
    func testEquality() {
        let x = G(.a, .b) | W(.g) | T(.c) | { }
        var y = G(.a, .b) | W(.g) | T(.c) | { }
        XCTAssertEqual(x, y)

        y =     G(.a, .a) | W(.g) | T(.c) | { }
        XCTAssertNotEqual(x, y)
        y =     G(.a, .b) | W(.h) | T(.c) | { }
        XCTAssertNotEqual(x, y)
        y =     G(.a, .b) | W(.g) | T(.b) | { }
        XCTAssertNotEqual(x, y)
    }

    func testBuilder() {
        let t = Transition.build {
            G(.a, .b) | W(.g) | T(.c) | { }
            G(.c)     | W(.h) | T(.d) | { }
            G(.d)     | W(.i) | T(.e) | { }
            G(.e)     | W(.j) | T(.f) | { }
        }

        XCTAssertEqual(t.count, 5)
    }
    
    func testGivenBuilder() {
        let t = G(.a, .b) {
            W(.h) | T(.b) | { }
            W(.g) | T(.a) | { }
        }
        
        assertFirst(.a, .h, .b, t)
        assertLast(.b, .g, .a, t)
        assertCount(4, t)
    }
    
    func testGivenBuilderWithWhenThenArray() {
        let t = G(.a, .b) {
            [W(.h) | T(.b),
             W(.g) | T(.a)] | { }
        }
        
        assertFirst(.a, .h, .b, t)
        assertLast(.b, .g, .a, t)
        assertCount(4, t)
    }
    
    func testActionModifier() {
        let e = expectation(description: "call action")
        
        let t =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.action { e.fulfill() }
        
        assertFirst(.a, .h, .b, t)
        assertLast(.b, .g, .a, t)
        assertCount(4, t)
        
        t.first?.actions.first?()
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionsModifier() {
        let e = expectation(description: "call action")
        
        let t =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.actions({}, { e.fulfill() })
        
        assertFirst(.a, .h, .b, t)
        assertLast(.b, .g, .a, t)
        assertCount(4, t)
        
        t.first?.actions.last?()
        waitForExpectations(timeout: 0.1)
    }

    func assertAction(_ e: XCTestExpectation) {
        e.fulfill()
    }

    func testActionPassedCorrectly() {
        let e = expectation(description: "passAction")
        let t = G(.a) | W(.g) | T(.c) | {
            self.assertAction(e)
        }
        t.first?.actions.first?()
        waitForExpectations(timeout: 0.1)
    }
    
    func testBuilderIfTrue() {
        let condition = true
        let ts = Transition.build {
            if condition {
                G(.a) | W(.g) | T(.b) | { }
            }
        }
        XCTAssertEqual(ts.first, transition(.a, .g, .b))
    }
    
    func testBuilderIfFalse() {
        let condition = false
        let ts = Transition.build {
            if condition {
                G(.a) | W(.g) | T(.b) | { }
            }
        }
        XCTAssert(ts.isEmpty)
    }
    
    func testBuilderElse() {
        let test = false
        let ts = Transition.build {
            if test {
                G(.a) | W(.g) | T(.b) | { }
                G(.a) | W(.h) | T(.b) | { }
            } else {
                G(.b) | W(.i) | T(.b) | { }
            }
        }
        XCTAssertEqual(ts.count, 1)
        XCTAssertEqual(ts.first, transition(.b, .i, .b))
    }
    
    func testBuilderSwitch() {
        enum Switchy { case on, off }
        
        let state = Switchy.on
        let ts = Transition.build {
            switch state {
            case .on:  G(.a) | W(.g) | T(.b) | { }
            case .off: G(.b) | W(.i) | T(.b) | { }
            }
        }
        XCTAssertEqual(ts.first, transition(.a, .g, .b))
    }
}

class SuperStateTransitionTests: SafeTests {
    func testWithBuilder() {
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
    
    let s = SuperState {
        W(.h) | T(.b) | { }
    }
    
    func testGiven() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assertFirst(.a, .h, .b, t)
            assertLast(.a, .g, .s, t)
            assertCount(2, t)
        }
        
        let t1 = G(.a, superState: s) {
            W(.g) | T(.s) | { }
        }
        let t2 = G(.a, superState: s) | W(.g) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGiven() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .b, .h, .b, t)
            assert(i: 3, .b, .g, .s, t)
            assertCount(4, t)
        }
        
        let t1 = G(.a, .b, superState: s) {
            W(.g) | T(.s) | { }
        }
        let t2 = G(.a, .b, superState: s) | W(.g) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleWhenThenAction() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, superState: s) {
            W(.g) | T(.s) | { }
            W(.h) | T(.s) | { }
        }
        let t2 = G(.a, superState: s) | [W(.g) | T(.s) | { },
                                         W(.h) | T(.s) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWTA() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            
            assert(i: 3, .b, .h, .b, t)
            assert(i: 4, .b, .g, .s, t)
            assert(i: 5, .b, .h, .s, t)
            assertCount(6, t)
        }
        
        let t1 = G(.a, .b, superState: s) {
            W(.g) | T(.s) | { }
            W(.h) | T(.s) | { }
        }
        let t2 = G(.a, .b, superState: s) | [W(.g) | T(.s) | { },
                                             W(.h) | T(.s) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultitipleWhen() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, superState: s) {
            W(.g, .h) | T(.s) | { }
        }
        let t2 = G(.a, superState: s) | W(.g, .h) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWhen() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            
            assert(i: 3, .b, .h, .b, t)
            assert(i: 4, .b, .g, .s, t)
            assert(i: 5, .b, .h, .s, t)
            assertCount(6, t)
        }
        
        let t1 = G(.a, .b, superState: s) {
            W(.g, .h) | T(.s) | { }
        }
        let t2 = G(.a, .b, superState: s) | W(.g, .h) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWhenMultipleThenAction() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            assert(i: 3, .a, .i, .d, t)
            assert(i: 4, .a, .j, .d, t)
            
            assert(i: 5, .b, .h, .b, t)
            assert(i: 6, .b, .g, .s, t)
            assert(i: 7, .b, .h, .s, t)
            assert(i: 8, .b, .i, .d, t)
            assert(i: 9, .b, .j, .d, t)
            assertCount(10, t)
        }
        
        let t1 = G(.a, .b, superState: s) {
            W(.g, .h) | T(.s) | { }
            W(.i, .j) | T(.d) | { }
        }
        let t2 = G(.a, .b, superState: s) | [W(.g, .h) | T(.s) | { },
                                             W(.i, .j) | T(.d) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleWhenThen() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, superState: s) {
            [W(.g) | T(.s),
             W(.h) | T(.s)] | { }
        }
        let t2 = G(.a, superState: s) | [W(.g) | T(.s),
                                         W(.h) | T(.s)] | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testAll() {
        func assertOutput(_ t: [Transition<State, Event>]) {
            assert(i: 0, .a, .h, .b, t)
            
            assert(i: 1, .a, .g, .s, t)
            assert(i: 2, .a, .h, .s, t)
            assert(i: 3, .a, .h, .t, t)
            assert(i: 4, .a, .i, .t, t)
            assert(i: 5, .a, .i, .s, t)
            assert(i: 6, .a, .j, .s, t)
            assert(i: 7, .a, .j, .t, t)
            assert(i: 8, .a, .k, .t, t)
            
            assert(i: 9, .b, .h, .b, t)
            
            assert(i: 10, .b, .g, .s, t)
            assert(i: 11, .b, .h, .s, t)
            assert(i: 12, .b, .h, .t, t)
            assert(i: 13, .b, .i, .t, t)
            assert(i: 14, .b, .i, .s, t)
            assert(i: 15, .b, .j, .s, t)
            assert(i: 16, .b, .j, .t, t)
            assert(i: 17, .b, .k, .t, t)

            assertCount(18, t)
        }
        
        let t1 = G(.a, .b, superState: s) {
            [W(.g, .h) | T(.s),
             W(.h, .i) | T(.t)] | { }
            
            [W(.i, .j) | T(.s),
             W(.j, .k) | T(.t)] | { }
        }
        
         let t2 = G(.a, .b, superState: s) | [[W(.g, .h) | T(.s),
                                              W(.h, .i) | T(.t)] | { },
                                             
                                             [W(.i, .j) | T(.s),
                                              W(.j, .k) | T(.t)] | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
}

class FileLineTests: SafeTests {
    func testFileAndLine() {
        let file: String = String(#file)
        
        let line1 = #line; let t1 = G(.a) {
            W(.g) | T(.s) | { }
        }
        let line2 = #line; let t2 = G(.a) | W(.g) | T(.s) | { }
        
        XCTAssertEqual(t1.first?.line, line1)
        XCTAssertEqual(t2.first?.line, line2)
        
        XCTAssertEqual(t1.first?.file, file)
        XCTAssertEqual(t2.first?.file, file)
    }
#warning("really the line should be whatever line has the 'then' in it")
}

class DemonstrationTests: SafeTests {
    func testNestedBuilder() {
        let t = Transition.build {
            G(.a) | W(.h) | T(.b) | doNothing
            G(.a) | W(.g) | T(.a) | doNothing
            G(.b) | W(.h) | T(.b) | doNothing
            G(.b) | W(.g) | T(.a) | doNothing
            
            G(.c) | [W(.h) | T(.b) | doNothing,
                     W(.g) | T(.a) | doNothing]
            G(.d) | [W(.h) | T(.b) | doNothing,
                     W(.g) | T(.a) | doNothing]
            
            G(.e) {
                W(.h) | T(.b) | doNothing
                W(.g) | T(.a) | doNothing
            }
            G(.f) {
                W(.h) | T(.b) | doNothing
                W(.g) | T(.a) | doNothing
            }
            
            G(.p, .q) {
                W(.h) | T(.b) | doNothing
                W(.g) | T(.a) | doNothing
            }
            
            G(.r, .s) | [W(.h) | T(.b),
                         W(.g) | T(.a)] | doNothing
            
            G(.t, .u) {
                [W(.h) | T(.b),
                 W(.g) | T(.a)] | doNothing
            }
            
            G(.v, .w) {
                W(.h) | T(.b)
                W(.g) | T(.a)
            }.action(doNothing)
        }
        
        XCTAssertEqual(t.count, 28)
    }
    
    func testTurnstile() {
        typealias W = When<String>
        typealias T = Then<String>
        
        let _ =
"""
Initial: Locked
FSM: Turnstile
{
  // This is an abstract super state.
  (Resetable)  {
    Reset       Locked       {alarmOff lock}
  }
  Locked : Resetable    {
    Coin    Unlocked    unlock
    Pass    Alarming    alarmOn
  }
  Unlocked : Resetable {
    Coin    Unlocked    thankyou
    Pass    Locked      lock
  }
  Alarming : Resetable { // inherits all it's transitions from Resetable.
  }
}
"""
        func alarmOff() {}
        func unlock() {}
        func alarmOn() {}
        func thankyou() {}
        func lock() {}
        
        let _ = Transition.build {
            /*
             let resetable = Superstate {
                W("Reset") | T("Locked")   | "alarmOff"; "lock"
             }
             // what about multiple givens with different inhereitances?
             Given("Locked") :: resetable {
                 W("Coin") | T("Unlocked") | "unlock"
                 W("Pass") | T("Alarming") | "alarmOn"
             }
             
             Given("Unlocked") :: resetable {
                 W("Coin") | T("Unlocked") | "thankyou"
                 W("Pass") | T("Locked")   | "lock"
             }
             
             Given("Alarming") :: resetable
            
             */
            
            Given("Locked", "Unlocked", "Alarming") {
                W("Reset") | T("Locked")  | [alarmOff, lock]
            }
            
            Given("Locked") {
                W("Coin") | T("Unlocked") | unlock
                W("Pass") | T("Alarming") | alarmOn
            }
            
            Given("Unlocked") {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }
        }
    }
}
