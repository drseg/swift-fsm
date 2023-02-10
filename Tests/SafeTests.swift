//
//  SafeTests.swift
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class SafeTests: XCTestCase {
    enum State: StateProtocol { case a, b, c, d, e, f, p, q, r, s, t, u, v, w }
    enum Event: EventProtocol { case g, h, i, j, k, l, m, n, o}

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
        line: UInt = #line,
        file: StaticString = #file
    ) {
        assertContains(sess, tr.transitions, line: line, file: file)
    }

    func assertContains(
        _ sess: [(State, Event, State)],
        _ tr: [Transition<State, Event>],
        line: UInt = #line,
        file: StaticString = #file
    ) {
        sess.forEach {
            assertContains($0.0, $0.1, $0.2, tr, line: line, file: file)
        }
    }

    func assertContains(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ tr: TR,
        line: UInt = #line,
        file: StaticString = #file
    ) {
        assertContains(given, when, then, tr.transitions, line: line, file: file)
    }

    func assertContains(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ tr: [Transition<State, Event>],
        line: UInt = #line,
        file: StaticString = #file
    ) {
        XCTAssertTrue(tr.contains(where: {
            $0.givenState == given &&
            $0.event == when &&
            $0.nextState == then
        }), file: file, line: line)
    }

    func assertCount(
        _ expected: Int,
        _ tr: TR,
        line: UInt = #line,
        file: StaticString = #file
    ) {
        assertCount(expected, tr.transitions, line: line, file: file)
    }

    func assertCount(
        _ expected: Int,
        _ tr: [Transition<State, Event>],
        line: UInt = #line,
        file: StaticString = #file
    ) {
        XCTAssertEqual(tr.count, expected, file: file, line: line)
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

class DemonstrationTests: SafeTests {
    func alarmOff() {}; func unlock() {}; func alarmOn() {}
    func thankyou() {}; func lock() {}
    
    func testCompilation() {
        typealias W = When<String>; typealias T = Then<String>
        
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
            
            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }
            
            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }
            
            Given("Unlocked").include(resetable) {
                W("Coin") | T("Unlocked") | thankyou
                W("Pass") | T("Locked")   | lock
            }
            
            Given("Alarming").include(resetable)
            Given("Alarming").include(resetable)
            Given("Alarming").include(resetable)
            Given("Alarming").include(resetable)
            Given("Alarming").include(resetable)
        }
    }
        
    func testTurnstile() {
        typealias W = When<TurnstileEvent>
        typealias T = Then<TurnstileState>
        
        enum TurnstileState: SP {
            case locked, unlocked, alarming
        }
        
        enum TurnstileEvent: EP {
            case reset, coin, pass
        }
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
        let fsm = FSM<TurnstileState, TurnstileEvent>(initialState: .locked)
        try! fsm.buildTransitions {
            let resetable = SuperState {
                W(.reset) | T(.locked)  | [alarmOff, lock]
            }

            (Given(.locked) => resetable) {
                W(.coin) | T(.unlocked) | unlock
                W(.pass) | T(.alarming) | alarmOn
            }

            (Given(.unlocked) => resetable) {
                W(.coin) | T(.unlocked) | thankyou
                W(.pass) | T(.locked)   | lock
            }

            Given(.alarming) => resetable
        }
        
        /*
         let resetable = superState {
             when(.reset, then: .locked) { alarmOff(); lock() }
         }

         given(.locked).include(resetable) {
             when(.coin, then: .unlocked) { unlock() }
             when(.pass, then: .alarming) { alarmOn() }
         }

         given(.unlocked).include(resetable) {
             when(.coin, then: .unlocked) { thankyou() }
             when(.pass, then: .locked) { lock() }
         }

         given(.alarming).include(resetable)
         */
        
        /*
         let resetable = superState {
             when(.reset, then: .locked) { alarmOff(); lock() }
         }

         given(.locked) {
             include(resetable) {
                 when(.coin, then: .unlocked) { unlock()  }
                 when(.pass, then: .alarming) { alarmOn() }
             }
         }
         .onEnter {}
         .onLeave {}

         given(.unlocked) {
             include(resetable) {
                 when(.coin, then: .unlocked) { thankyou() }
                 when(.pass, then: .locked) { lock() }
             }
         }

         given(.alarming).include(resetable)
         */
        
        
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
         
         let resetable = SuperState {
             W("Reset") | T("Locked")  | []
         }

         Given("Locked") => resetable <lock {
             W("Coin") | T("Unlocked") | []
             W("Pass") | T("Alarming") | []
         }
         
         (Given("Unlocked") => resetable <unlock) {
             W("Coin") | T("Unlocked") | thankyou
             W("Pass") | T("Alarming") | []
         }
         
         Given("Alarming") => resetable <alarmOn >alarmOff
         */
    }
}
