//
//  ClassTransitionTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import XCTest
@testable import FiniteStateMachine

final class UnsafeTransitionTests: XCTestCase {
    typealias State = StateProtocol
    typealias Event = EventProtocol
    typealias ASP = Unsafe.AnyStateProtocol
    typealias AEP = Unsafe.AnyEventProtocol
    
    typealias Transition = FiniteStateMachine.Transition<Unsafe.AnyStateProtocol,
                                                         Unsafe.AnyEventProtocol>
    typealias Key = Transition.Key<Unsafe.AnyStateProtocol,
                                   Unsafe.AnyEventProtocol>

    struct S1: State {}
    struct S2: State {}
    struct S3: State {}

    struct E1: Event {}
    struct E2: Event {}
    struct E3: Event {}

    var actionCalled = false
    func action() { actionCalled = true }

    func transition(
        _ givenState: any StateProtocol,
        _ event: any EventProtocol,
        _ nextState: any StateProtocol
    ) -> Transition {
        Transition(givenState: givenState.erased!,
                   event: event.erased!,
                   nextState: nextState.erased!,
                   action: { })
    }
    
    func key(_ state: any StateProtocol, _ event: any EventProtocol) -> Key {
        Key(state: state.erased!,
            event: event.erased!)
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
    
    func testHashable() {
        let test = Set([S1().erased,
                        S1().erased,
                        S2().erased])
        XCTAssertEqual(test.count, 2)
    }

    func testTransition() {
        t = S1() | E1() | S2() | action
        assertFirst(transition(S1(), E1(), S2()))
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
        t = S1() | E1() | S2() | action
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

