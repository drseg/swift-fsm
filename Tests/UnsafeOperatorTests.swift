//
//  ClassTransitionTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class UnsafeTransitionTests: XCTestCase {
    typealias State = StateProtocol
    typealias Event = EventProtocol
    typealias ASP = Unsafe.AnyStateProtocol
    typealias AEP = Unsafe.AnyEventProtocol
    
    typealias Transition = FiniteStateMachine.Transition<Unsafe.AnyStateProtocol,
                                                         Unsafe.AnyEventProtocol>
    typealias Key = Transition.Key<Unsafe.AnyStateProtocol,
                                   Unsafe.AnyEventProtocol>
    
    var s1: ASP { fatalError("") }
    var s2: ASP { fatalError("") }
    var s3: ASP { fatalError("") }
    
    var e1: AEP { fatalError("") }
    var e2: AEP { fatalError("") }
    var e3: AEP { fatalError("") }
    
    var actionCalled = false
    func action() { actionCalled = true }
    
    open override func perform(_ run: XCTestRun) {
        if Self.self != UnsafeTransitionTests.self {
            super.perform(run)
        }
    }

    func transition(
        _ givenState: ASP,
        _ event: AEP,
        _ nextState: ASP
    ) -> Transition {
        Transition(givenState: givenState,
                   event: event,
                   nextState: nextState,
                   action: { })
    }
    
    func key(_ state: ASP, _ event: AEP) -> Key {
        Key(state: state,
            event: event)
    }

    var t: [Transition] = []

    func assertFirst(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.first, expected, line: line)
    }
    
    func assertFirst(_ given: ASP, _ when: AEP, _ then: ASP, line: UInt = #line) {
        XCTAssertEqual(t.first, transition(given, when, then), line: line)
    }
    
    func assertLast(_ given: ASP, _ when: AEP, _ then: ASP, line: UInt = #line) {
        XCTAssertEqual(t.last, transition(given, when, then), line: line)
    }

    func assertLast(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.last, expected, line: line)
    }

    func assertCount(_ expected: Int, line: UInt = #line) {
        XCTAssertEqual(t.count, expected, line: line)
    }
    
    func testHashable() {
        let test = Set([s1,
                        s1,
                        s2])
        XCTAssertEqual(test.count, 2)
    }

    func testTransition() {
        t = s1 | e1 | s2 | action
        assertFirst(transition(s1, e1, s2))
    }

    func testMultipleStartEventFinishes() {
        t = [s1 | e1 | s2,
             s2 | e1 | s2] | action

        assertFirst(transition(s1, e1, s2))
        assertLast(transition(s2, e1, s2))
    }
    
    func testMultipleStartEvents() {
        t = [s1 | e1,
             s2 | e1] | s2 | action
        
        assertFirst(transition(s1, e1, s2))
        assertLast(transition(s2, e1, s2))
    }
    
    func testMultipleStarts() {
        t = [s1,
             s2] | e1 | s2 | action
        
        assertFirst(transition(s1, e1, s2))
        assertLast(transition(s2, e1, s2))
    }
    
    func testMultipleEvents() {
        t = s1 | [e1, e2] | s2 | action
        
        assertFirst(transition(s1, e1, s2))
        assertLast(transition(s1, e2, s2))
    }
    
    func testNesting() {
        t = [s2,
             s1] | [e1,
                    e2] | s2 | action
        
        assertFirst(transition(s2, e1, s2))
        assertLast(transition(s1, e2, s2))
    }
    
    func testMultipleEventStateAction() {
        t = s1 | [e1 | s2 | {},
                  e2 | s3 | {}]
        
        assertFirst(s1, e1, s2)
        assertLast(s1, e2, s3)
    }
    
    func testMultipleStateEventStateAction() {
        t = [s1,
             s2] | [e1 | s2 | {},
                    e2 | s3 | {}]
        
        assertFirst(s1, e1, s2)
        assertLast(s2, e2, s3)
    }
    
    func testMultipleStateEventEventStateAction() {
        t = s1 | [[e1, e2] | s2 | {},
                  [e2, e3] | s3 | {}]
        assertFirst(s1, e1, s2)
        assertLast(s1, e3, s3)
    }
    
    func testMultipleStatesEventEventStateAction() {
        t = [s1, s2] | [[e1, e2] | s2 | {},
                        [e2, e3] | s3 | {}]
        assertFirst(s1, e1, s2)
        assertLast(s2, e3, s3)
    }
    
    func testMultipleEventStates() {
        t = s1 | [e1 | s2,
                  e2 | s3] | {}
        assertFirst(s1, e1, s2)
        assertLast(s1, e2, s3)
    }
    
    func testMultipleStatesEventStates() {
        t = [s1, s2] | [e1 | s2,
                        e2 | s3] | {}
        assertFirst(s1, e1, s2)
        assertLast(s2, e2, s3)
    }
    
    func testCallsAction() {
        t = s1 | e1 | s2 | action
        t.first?.action()
        XCTAssertTrue(actionCalled)
    }
    
    func testBuilder() {
        let t = Transition.build {
            s1   | e1 | s2 | action
            s2   | e2 | s1 | action
            
            [s2,
             s1] | e3 | s2 | action
        }
        XCTAssertEqual(t.count, 4)
    }

    func assertContainsTransition(
        _ t: [Key: Transition],
        k: Key,
        line: UInt = #line
    ) {
        let actual = t[k]
        XCTAssertEqual(actual, transition(s1, e1, s2), line: line)
    }

    func testCanRetrieveByKey() {
        let t = Transition.build {
            s1 | e1 | s2 | action
            s2 | e2 | s1 | action
        }

        assertContainsTransition(t, k: key(s1, e1))
    }

    func testIf() {
        let condition = true
        let t = Transition.build {
            if condition {
                s1 | e1 | s2 | action
            }
        }

        assertContainsTransition(t, k: key(s1, e1))
    }

    func testElse() {
        let condition = false
        let t = Transition.build {
            if condition {}
            else { s1 | e1 | s2 | action }
        }

        assertContainsTransition(t, k: key(s1, e1))
    }

    func testSwitch() {
        let condition = true
        let t = Transition.build {
            switch condition {
            case true:  s1 | e1 | s2 | action
            default: [Transition]()
            }
        }

        assertContainsTransition(t, k: key(s1, e1))
    }

    func testActionsDispatchDynamically() {
        class Base { func test() { XCTFail() } }
        class Sub: Base { override func test() {} }

        let t = s1 | e1 | s2 | Sub().test
        t.first?.action()
    }
    
    func testRespectsCustomStringConvertible() {
        // how do I test this?
    }
}

final class EnumTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S.one.erased! }
    override var s2: ASP { S.two.erased! }
    override var s3: ASP { S.three.erased! }
    
    override var e1: AEP { E.one.erased! }
    override var e2: AEP { E.two.erased! }
    override var e3: AEP { E.three.erased! }
    
    enum S: State { case one, two, three }
    enum E: Event { case one, two, three }
}

final class EnumValueTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S.one("").erased! }
    override var s2: ASP { S.two("").erased! }
    override var s3: ASP { S.three("").erased! }
    
    override var e1: AEP { E.one.erased! }
    override var e2: AEP { E.two.erased! }
    override var e3: AEP { E.three.erased! }
    
    enum S: State { case one(String), two(String), three(String) }
    enum E: Event { case one, two, three }
}

final class StructTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S1().erased! }
    override var s2: ASP { S2().erased! }
    override var s3: ASP { S3().erased! }
    
    override var e1: AEP { E1().erased! }
    override var e2: AEP { E2().erased! }
    override var e3: AEP { E3().erased! }
    
    struct S1: State {}; struct S2: State {}; struct S3: State {}
    struct E1: Event {}; struct E2: Event {}; struct E3: Event {}
}

final class UnsafeClassTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S1().erased! }
    override var s2: ASP { S2().erased! }
    override var s3: ASP { S3().erased! }

    override var e1: AEP { E1().erased! }
    override var e2: AEP { E2().erased! }
    override var e3: AEP { E3().erased! }

    class S1: State {}; class S2: State {}; class S3: State {}
    class E1: Event {}; class E2: Event {}; class E3: Event {}
}

