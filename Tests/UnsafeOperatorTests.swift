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
    
    typealias ASP = any StateProtocol
    typealias AEP = any EventProtocol
    
    typealias Transition = FiniteStateMachine.Transition<Unsafe.AnyState,
                                                         Unsafe.AnyEvent>
    typealias Key = Transition.Key<Unsafe.AnyState,
                                   Unsafe.AnyEvent>
    
    var s1: ASP { mustImplement() }
    var s2: ASP { mustImplement() }
    var s3: ASP { mustImplement() }
    
    var e1: AEP { mustImplement() }
    var e2: AEP { mustImplement() }
    var e3: AEP { mustImplement() }
    
    private func mustImplement() -> Never {
        fatalError("tests must implement")
    }
    
    var actionCalled = false
    func action() { actionCalled = true }
    
    override func perform(_ run: XCTestRun) {
        if Self.self != UnsafeTransitionTests.self {
            super.perform(run)
        }
    }

    func transition(
        _ givenState: ASP,
        _ event: AEP,
        _ nextState: ASP
    ) -> Transition {
        Transition(givenState: givenState.erased,
                   event: event.erased,
                   nextState: nextState.erased,
                   action: { })
    }
    
    func key(_ state: ASP, _ event: AEP) -> Key {
        Key(state: state.erased,
            event: event.erased)
    }

    var t: [Transition] = []
    
    func assertFirst(
        _ given: ASP,
        _ when: AEP,
        _ then: ASP,
        line: UInt = #line
    ) {
        XCTAssertEqual(t.first, transition(given, when, then), line: line)
    }
    
    func assertLast(
        _ given: ASP,
        _ when: AEP,
        _ then: ASP,
        line: UInt = #line
    ) {
        XCTAssertEqual(t.last, transition(given, when, then), line: line)
    }

    func testTransition() {
        t = s1 | e1 | s2 | action
        assertFirst(s1, e1, s2)
    }

    func testMultipleStartEventFinishes() {
        t = [s1 | e1 | s2,
             s2 | e1 | s2] | action

        assertFirst(s1, e1, s2)
        assertLast(s2, e1, s2)
    }
    
    func testMultipleStartEvents() {
        t = [s1 | e1,
             s2 | e1] | s2 | action
        
        assertFirst(s1, e1, s2)
        assertLast(s2, e1, s2)
    }
    
    func testMultipleStarts() {
        t = [s1,
             s2] | e1 | s2 | action
        
        assertFirst(s1, e1, s2)
        assertLast(s2, e1, s2)
    }
    
    func testMultipleEvents() {
        t = s1 | [e1, e2] | s2 | action
        
        assertFirst(s1, e1, s2)
        assertLast(s1, e2, s2)
    }
    
    func testNesting() {
        t = [s2,
             s1] | [e1,
                    e2] | s2 | action
        
        assertFirst(s2, e1, s2)
        assertLast(s1, e2, s2)
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
            s1       | e1 | s2 | action
            s2       | e2 | s1 | action
            [s2, s1] | e3 | s2 | action
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
}

final class EnumTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S.one }
    override var s2: ASP { S.two }
    override var s3: ASP { S.three }
    
    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }
    
    enum S: State { case one, two, three }
    enum E: Event { case one, two, three }
}

final class EnumValueTransitionTestsOne: UnsafeTransitionTests {
    override var s1: ASP { S.one("") }
    override var s2: ASP { S.two("") }
    override var s3: ASP { S.three("") }
    
    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }
    
    enum S: State { case one(String), two(String), three(String) }
    enum E: Event { case one, two, three }
}

final class EnumValueTransitionTestsTwo: UnsafeTransitionTests {
    override var s1: ASP { S.one("1") }
    override var s2: ASP { S.one("2") }
    override var s3: ASP { S.one("3") }
    
    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }
    
    enum S: State { case one(String), two(String), three(String) }
    enum E: Event { case one, two, three }
}

final class StructTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S1() }
    override var s2: ASP { S2() }
    override var s3: ASP { S3() }
    
    override var e1: AEP { E1() }
    override var e2: AEP { E2() }
    override var e3: AEP { E3() }
    
    struct S1: State {}; struct S2: State {}; struct S3: State {}
    struct E1: Event {}; struct E2: Event {}; struct E3: Event {}
}

protocol EqHa where Self: Hashable { }
extension EqHa {
    static func == (lhs: Self, rhs: Self) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
    
    func hash(into hasher: inout Hasher) { }
}

final class ClassTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S1() }
    override var s2: ASP { S2() }
    override var s3: ASP { S3() }

    override var e1: AEP { E1() }
    override var e2: AEP { E2() }
    override var e3: AEP { E3() }

    class S1: State, EqHa {}; class S2: State, EqHa {}; class S3: State, EqHa {}
    class E1: Event, EqHa {}; class E2: Event, EqHa {}; class E3: Event, EqHa {}
}

final class StringIntTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { "s1" }
    override var s2: ASP { "s2" }
    override var s3: ASP { "s3" }

    override var e1: AEP { 1 }
    override var e2: AEP { 2 }
    override var e3: AEP { 3 }
}

final class MixedMessTests: UnsafeTransitionTests {
    override var s1: ASP { "s1" }
    override var s2: ASP { 2 }
    override var s3: ASP { false }

    override var e1: AEP { 1 }
    override var e2: AEP { "e2" }
    override var e3: AEP { true }
}

extension String: StateProtocol, EventProtocol {}
extension Int: EventProtocol, StateProtocol {}
extension Bool: EventProtocol, StateProtocol {}

protocol NeverEqual { }
extension NeverEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { false }
}

protocol AlwaysEqual { }
extension AlwaysEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

final class ErasedHashableConformanceTests: XCTestCase {
    struct NeverEqualState: StateProtocol, Hashable, NeverEqual { }
    struct AlwaysEqualState: StateProtocol, Hashable, AlwaysEqual { }
    struct NeverEqualEvent: EventProtocol, Hashable, NeverEqual { }
    struct AlwaysEqualEvent: EventProtocol, Hashable, AlwaysEqual { }
    
    func testStateInequality() {
        let s1 = NeverEqualState().erased
        let s2 = NeverEqualState().erased
    
        XCTAssertNotEqual(s1, s2)
    }
    
    func testStateEquality() {
        let s1 = AlwaysEqualState().erased
        let s2 = AlwaysEqualState().erased
    
        XCTAssertEqual(s1, s2)
    }

    func testEventInequality() {
        let e1 = NeverEqualEvent().erased
        let e2 = NeverEqualEvent().erased
    
        XCTAssertNotEqual(e1, e2)
    }

    func testEventEquality() {
        let e1 = AlwaysEqualEvent().erased
        let e2 = AlwaysEqualEvent().erased
    
        XCTAssertEqual(e1, e2)
    }

    func testStateFalseSet() {
        let s1 = NeverEqualState().erased
        let s2 = NeverEqualState().erased
        
        XCTAssertEqual(2, Set([s1, s2]).count)
    }

    func testStateTrueSet() {
        let s1 = AlwaysEqualState().erased
        let s2 = AlwaysEqualState().erased
        
        XCTAssertEqual(1, Set([s1, s2]).count)
    }

    func testEventFalseSet() {
        let e1 = NeverEqualEvent().erased
        let e2 = NeverEqualEvent().erased
        
        XCTAssertEqual(2, Set([e1, e2]).count)
    }

    func testEventTrueSet() {
        let e1 = AlwaysEqualEvent().erased
        let e2 = AlwaysEqualEvent().erased
        
        XCTAssertEqual(1, Set([e1, e2]).count)
    }

    func testStateDictionaryLookup() {
        let s1 = AlwaysEqualEvent().erased
        let s2 = NeverEqualEvent().erased

        let a = [s1: "Pass"]
        let b = [s2: "Pass"]

        XCTAssertEqual(a[s1], "Pass")
        XCTAssertNil(a[s2])

        XCTAssertNil(b[s2])
        XCTAssertNil(b[s1])
    }

    func testErasedWrapperUsesWrappedHasher() {
        struct StateSpy: StateProtocol, Hashable, NeverEqual {
            let callback: () -> ()
            func hash(into hasher: inout Hasher) { callback() }
        }
        
        let e = expectation(description: "hash")
        let wrapper = StateSpy() { e.fulfill() }.erased
        let _ = [wrapper: "Pass"]
        waitForExpectations(timeout: 0.1)
    }
}




