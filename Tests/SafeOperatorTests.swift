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
    typealias TG = Transition<State, Event>.Group
    
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
        _ given: State,
        _ when: Event,
        _ then: State,
        _ t: Transition<State, Event>.Group,
        line: UInt = #line
    ) {
        XCTAssertTrue(t.transitions.contains(where: {
            $0.givenState == given &&
            $0.event == when &&
            $0.nextState == then
        }))
    }
    
    func assertCount(
        _ expected: Int,
        _ t: Transition<State, Event>.Group,
        line: UInt = #line) {
        XCTAssertEqual(t.transitions.count, expected, line: line)
    }
    
    func doNothing() {}
}

final class SafeTransitionTests: SafeTests {
    func testSimpleConstructor() {
        let t = G(.a) | W(.g) | T(.b) | { }
        
        assertContains(.a, .g, .b, t)
    }
    
    func testMultiGivenConstructor() {
        let t = G(.a, .b) | W(.g) | T(.b) | { }
        
        assertContains(.a, .g, .b, t)
        assertContains(.b, .g, .b, t)
        assertCount(2, t)
    }
    
    func testMultiActionConstructor() {
        let _ = G(.a) | W(.g) | T(.b) | [{ }, { }]
        // nothing to assert here, just needs to compile
    }
    
    func testMultiWhenThenActionConstructor() {
        let t = G(.a) | [W(.g) | T(.b) | { },
                         W(.h) | T(.c) | { }]
        
        assertContains(.a, .g, .b, t)
        assertContains(.a, .h, .c, t)
        assertCount(2, t)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        let t = G(.a, .b) | [W(.g) | T(.c) | { },
                             W(.h) | T(.c) | { }]
        
        assertContains(.a, .g, .c, t)
        assertContains(.b, .h, .c, t)
        assertCount(4, t)
    }
    
    func testMultiWhenConstructor() {
        let t = G(.a) | W(.g, .h) | T(.c) | { }
        
        assertContains(.a, .g, .c, t)
        assertContains(.a, .h, .c, t)
        assertCount(2, t)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        let t = G(.a, .b) | W(.g, .h) | T(.c) | { }
        
        assertContains(.a, .g, .c, t)
        assertContains(.b, .h, .c, t)
        assertCount(4, t)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        let t = G(.a, .b) | [
            W(.g, .h) | T(.c) | { },
            W(.i, .j) | T(.d) | { }
        ]
        
        assertContains(.a, .g, .c, t)
        assertContains(.b, .j, .d, t)
        assertCount(8, t)
    }
    
    func testMultiWhenThenConstructor() {
        let t = G(.a) | [W(.g) | T(.c),
                         W(.h) | T(.d)] | { }
        
        assertContains(.a, .g, .c, t)
        assertContains(.a, .h, .d, t)
        assertCount(2, t)
    }
    
    func testMaxConstructors() {
        let t = G(.a, .b) | [[W(.g, .h) | T(.c),
                              W(.h, .i) | T(.d)] | { },
                             
                             [W(.i, .j) | T(.e),
                              W(.j, .k) | T(.f)] | { }]
        
        assertContains(.a, .g, .c, t)
        assertContains(.b, .k, .f, t)
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

    func testTransitionBuilder() {
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
        
        assertContains(.a, .h, .b, t)
        assertContains(.b, .g, .a, t)
        assertCount(4, t)
    }
    
    func testGivenBuilderWithWhenThenArray() {
        let t = G(.a, .b) {
            [W(.h) | T(.b),
             W(.g) | T(.a)] | { }
        }
        
        assertContains(.a, .h, .b, t)
        assertContains(.b, .g, .a, t)
        assertCount(4, t)
    }
    
    func testActionModifier() {
        let e = expectation(description: "call action")
        
        let t =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.action { e.fulfill() }
        
        assertContains(.a, .h, .b, t)
        assertContains(.b, .g, .a, t)
        assertCount(4, t)
        
        t.transitions.first?.actions.first?()
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionsModifier() {
        let e = expectation(description: "call action")
        
        let t =
        G(.a, .b) {
            W(.h) | T(.b)
            W(.g) | T(.a)
        }.actions({}, { e.fulfill() })
        
        assertContains(.a, .h, .b, t)
        assertContains(.b, .g, .a, t)
        assertCount(4, t)
        
        t.transitions.first?.actions.last?()
        waitForExpectations(timeout: 0.1)
    }

    func assertAction(_ e: XCTestExpectation) {
        e.fulfill()
    }

    func testActionPassedCorrectly() {
        let e = expectation(description: "passAction")
        let t = G(.a) | W(.g) | T(.c) | [{}, {
            self.assertAction(e)
        }]
        t.transitions.first?.actions.last?()
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
    
    let s = SuperState { W(.h) | T(.b) | { } }
#warning("no tests check a SuperState with more than one WTA")
    
    func testGiven() {
        func assertOutput(_ t: Transition<State, Event>.Group) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertCount(2, t)
        }
        
        let ss = SuperState {
            W(.h) | T(.b) | { }
            W(.g) | T(.s) | { }
        }
        
        let t1 = G(.a, include: s) {  W(.g) | T(.s) | { } }
        let t2 = G(.a, include: s) | W(.g) | T(.s) | { }
        let t3 = Transition.build {
            G(.a, include: ss)
        }
        let t4 = Transition.build {
            G(.a).include(ss)
        }
        
        assertOutput(t1)
        assertOutput(t2)
        assertOutput(TG(t3))
        assertOutput(TG(t4))
    }
    
    func testMultipleGiven() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.b, .h, .b, t)
            assertContains(.b, .g, .s, t)
            assertCount(4, t)
        }
        
        let t1 = G(.a, .b, include: s) { W(.g) | T(.s) | { } }
        let t2 = G(.a, .b, include: s) | W(.g) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleWhenThenAction() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, include: s) {
            W(.g) | T(.s) | { }
            W(.h) | T(.s) | { }
        }
        let t2 = G(.a, include: s) | [W(.g) | T(.s) | { },
                                         W(.h) | T(.s) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWTA() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            
            assertContains(.b, .h, .b, t)
            assertContains(.b, .g, .s, t)
            assertContains(.b, .h, .s, t)
            assertCount(6, t)
        }
        
        let t1 = G(.a, .b, include: s) {
            W(.g) | T(.s) | { }
            W(.h) | T(.s) | { }
        }
        let t2 = G(.a, .b, include: s) | [W(.g) | T(.s) | { },
                                             W(.h) | T(.s) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultitipleWhen() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, include: s) {
            W(.g, .h) | T(.s) | { }
        }
        let t2 = G(.a, include: s) | W(.g, .h) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWhen() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            
            assertContains(.b, .h, .b, t)
            assertContains(.b, .g, .s, t)
            assertContains(.b, .h, .s, t)
            assertCount(6, t)
        }
        
        let t1 = G(.a, .b, include: s) {
            W(.g, .h) | T(.s) | { }
        }
        let t2 = G(.a, .b, include: s) | W(.g, .h) | T(.s) | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleGivenMultipleWhenMultipleThenAction() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            assertContains(.a, .i, .d, t)
            assertContains(.a, .j, .d, t)
            
            assertContains(.b, .h, .b, t)
            assertContains(.b, .g, .s, t)
            assertContains(.b, .h, .s, t)
            assertContains(.b, .i, .d, t)
            assertContains(.b, .j, .d, t)
            assertCount(10, t)
        }
        
        let t1 = G(.a, .b, include: s) {
            W(.g, .h) | T(.s) | { }
            W(.i, .j) | T(.d) | { }
        }
        let t2 = G(.a, .b, include: s) | [W(.g, .h) | T(.s) | { },
                                             W(.i, .j) | T(.d) | { }]
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testMultipleWhenThen() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            assertCount(3, t)
        }
        
        let t1 = G(.a, include: s) {
            [W(.g) | T(.s),
             W(.h) | T(.s)] | { }
        }
        let t2 = G(.a, include: s) | [W(.g) | T(.s),
                                         W(.h) | T(.s)] | { }
        
        assertOutput(t1)
        assertOutput(t2)
    }
    
    func testAll() {
        func assertOutput(_ t: TGroup<State, Event>) {
            assertContains(.a, .h, .b, t)
            
            assertContains(.a, .g, .s, t)
            assertContains(.a, .h, .s, t)
            assertContains(.a, .h, .t, t)
            assertContains(.a, .i, .t, t)
            assertContains(.a, .i, .s, t)
            assertContains(.a, .j, .s, t)
            assertContains(.a, .j, .t, t)
            assertContains(.a, .k, .t, t)
            
            assertContains(.b, .h, .b, t)
            
            assertContains(.b, .g, .s, t)
            assertContains(.b, .h, .s, t)
            assertContains(.b, .h, .t, t)
            assertContains(.b, .i, .t, t)
            assertContains(.b, .i, .s, t)
            assertContains(.b, .j, .s, t)
            assertContains(.b, .j, .t, t)
            assertContains(.b, .k, .t, t)

            assertCount(18, t)
        }
        
        let t1 = G(.a, .b, include: s) {
            [W(.g, .h) | T(.s),
             W(.h, .i) | T(.t)] | { }
            
            [W(.i, .j) | T(.s),
             W(.j, .k) | T(.t)] | { }
        }
        
         let t2 = G(.a, .b, include: s) | [[W(.g, .h) | T(.s),
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
        
        XCTAssertEqual(t1.transitions.first?.line, line1)
        XCTAssertEqual(t2.transitions.first?.line, line2)
        
        XCTAssertEqual(t1.transitions.first?.file, file)
        XCTAssertEqual(t2.transitions.first?.file, file)
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
        
        func alarmOff() {}
        func unlock() {}
        func alarmOn() {}
        func thankyou() {}
        func lock() {}
        
        /*
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
         */
        
        let _ = Transition.build {
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
    }
}
