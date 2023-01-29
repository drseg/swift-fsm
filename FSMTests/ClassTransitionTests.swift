//
//  ClassTransitionTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import XCTest
@testable import FiniteStateMachine

final class ClassBasedTransitionTests: XCTestCase {
    typealias State = Class.State
    typealias Event = Class.Event
    typealias Transition = FiniteStateMachine.Transition<State, Event>
    typealias Key = Transition.Key<State, Event>
    
    class S1: State {}
    class S2: State {}
    class S3: State {}
    
    class E1: Event {}
    class E2: Event {}
    class E3: Event {}
    
    var actionCalled = false
    func action() { actionCalled = true }
    
    func transition(
        _ givenState: State,
        _ event: Event,
        _ nextState: State
    ) -> Transition {
        Transition(givenState: givenState,
                   event: event,
                   nextState: nextState,
                   action: { })
    }
    
    var t: [Transition] = []
    
    func assertFirst(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.first, expected, line: line)
    }
    
    func assertLast(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.last, expected, line: line)
    }
    
    func assertCount(_ expected: Int, line: UInt = #line) {
        XCTAssertEqual(t.count, expected, line: line)
    }
    
    func testStateEvent() {
        let se = S1() | E1()
        
        XCTAssertEqual(se.state, S1())
        XCTAssertEqual(se.event, E1())
    }
    
    func testMultiStateEvent() {
        let ses = [S1(),
                   S2()] | E1()
        
        XCTAssertEqual(ses.first?.state, S1())
        XCTAssertEqual(ses.last?.state, S2())
    }
    
    func testEventState() {
        let es = E1() | S1()
        
        XCTAssertEqual(es.event, E1())
        XCTAssertEqual(es.state, S1())
    }
    
    func testMultiEventState() {
        let ess = [E1(),
                   E2()] | S1()
        
        XCTAssertEqual(ess.first?.event, E1())
        XCTAssertEqual(ess.last?.event, E2())
    }
    
    func testStateAction() {
        let sa = S1() | action
        XCTAssertEqual(sa.state, S1())
    }
    
    func testStateEventState() {
        let ses = S1() | E1() | S2()
        
        XCTAssertEqual(ses.startState, S1())
        XCTAssertEqual(ses.event, E1())
        XCTAssertEqual(ses.endState, S2())
    }
    
    func testHashable() {
        let test = Set([S1(), S1(), S2()])
        XCTAssertEqual(test.count, 2)
    }
    
    func testTransition() {
        let t = S1() | E1() | S2() | action
        XCTAssertEqual(t.first, transition(S1(), E1(), S2()))
    }
    
    func testMultipleStartEventFinishes() {
        t = [S1() | E1() | S2(),
             S2() | E1() | S3()] | action
        
        assertFirst(transition(S1(), E1(), S2()))
        assertLast(transition(S2(), E1(), S3()))
    }
    
    func testMultipleStartEvents() {
        t = [S1() | E1(),
             S2() | E1()] | S3() | action
        
        assertFirst(transition(S1(), E1(), S3()))
        assertLast(transition(S2(), E1(), S3()))
    }
    
    func testMultipleStarts() {
        t = [S1(),
             S2()] | E1() | S3() | action
        
        assertFirst(transition(S1(), E1(), S3()))
        assertLast(transition(S2(), E1(), S3()))
    }
    
    func testNesting() {
        t = [S2(),
             S1()] | [E1(),
                      E2()] | S2() | action
        
        assertFirst(transition(S2(), E1(), S2()))
        assertLast(transition(S1(), E2(), S2()))
    }
    
    func testCallsAction() {
        let t = S1() | E1() | S2() | action
        t.first?.action()
        XCTAssertTrue(actionCalled)
    }
    
    func testBuilder() {
        let t = Transition.build {
            S1()   | E1() | S2() | action
            S2()   | E2() | S1() | action
            
            [S3(),
             S1()] | E3() | S2() | action
        }
        XCTAssertEqual(t.count, 4)
    }
    
    func key(_ state: State, _ event: Event) -> Key {
        Key(given: state, event: event)
    }

    func assertContainsTransition(
        _ t: [Key: Transition],
        k: Key,
        line: UInt = #line
    ) {
        let actual = t[k]
        XCTAssertEqual(actual, transition(S1(), E1(), S2()), line: line)
    }

    func testCanRetrieveByKey() {
        let t = Transition.build {
            S1() | E1() | S2() | action
            S2() | E2() | S1() | action
        }

        assertContainsTransition(t, k: key(S1(), E1()))
    }

    func testIf() {
        let condition = true
        let t = Transition.build {
            if condition {
                S1() | E1() | S2() | action
            }
        }

        assertContainsTransition(t, k: key(S1(), E1()))
    }

    func testElse() {
        let condition = false
        let t = Transition.build {
            if condition {}
            else { S1() | E1() | S2() | action }
        }

        assertContainsTransition(t, k: key(S1(), E1()))
    }

    func testSwitch() {
        let condition = true
        let t = Transition.build {
            switch condition {
            case true:  S1() | E1() | S2() | action
            default: [Transition]()
            }
        }

        assertContainsTransition(t, k: key(S1(), E1()))
    }
    
    func testActionsDispatchDynamically() {
        class Base { func test() { XCTFail() } }
        class Sub: Base { override func test() {} }
        
        let t = S1() | E1() | S2() | Sub().test
        t.first?.action()
    }
}

