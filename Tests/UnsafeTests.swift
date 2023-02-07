//
//  UnsafeTests.swift
//
//  Created by Daniel Segall on 29/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class UnsafeTests: XCTestCase {
    typealias SP = StateProtocol
    typealias EP = EventProtocol

    typealias ASP = any StateProtocol
    typealias AEP = any EventProtocol

    typealias T = FiniteStateMachine.Transition<AS, AE>
    typealias K = T.Key

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
        if Self.self != UnsafeTests.self {
            super.perform(run)
        }
    }

    func transition(_ givenState: ASP, _ event: AEP, _ nextState: ASP) -> T {
        T(givenState: givenState.erase,
          event: event.erase,
          nextState: nextState.erase,
          actions: [])
    }

    func key(_ state: ASP, _ event: AEP) -> K {
        K(state: state.erase,
          event: event.erase)
    }

    var t: TableRow<AS, AE>!

    func assertFirst(
        _ given: ASP,
        _ when: AEP,
        _ then: ASP,
        line: UInt = #line
    ) {
        XCTAssertEqual(t.transitions.first, transition(given, when, then),
                       line: line)
    }

    func assertLast(
        _ given: ASP,
        _ when: AEP,
        _ then: ASP,
        line: UInt = #line
    ) {
        XCTAssertEqual(t.transitions.last, transition(given, when, then),
                       line: line)
    }

    func testSingleRow() {
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
        t.transitions.first?.actions.first?()
        XCTAssertTrue(actionCalled)
    }

    func testBuilder() {
        let t = build {
            s1       | e1 | s2 | action
            s2       | e2 | s1 | action
            [s2, s1] | e3 | s2 | action
        }
        XCTAssertEqual(t.count, 4)
    }

    func assertContainsTransition(
        _ t: [T],
        _ s: ASP,
        _ e: AEP,
        line: UInt = #line
    ) {
        let actual = t.first {
            $0.givenState == s.erase && $0.event == e.erase
        }
        XCTAssertEqual(actual, transition(s1, e1, s2), line: line)
    }

    func testIf() {
        let condition = true
        let t = build {
            if condition {
                s1 | e1 | s2 | action
            }
        }

        assertContainsTransition(t, s1, e1)
    }

    func testElse() {
        let condition = false
        let t = build {
            if condition {
                s2 | e1 | s3 | action
            }
            else {
                s1 | e1 | s2 | action
            }
        }

        assertContainsTransition(t, s1, e1)
    }

//    func testSwitch() {
//        let condition = true
//        let t = build {
//            switch condition {
//            case true:  s1 | e1 | s2 | action
//            default: []
//            }
//        }
//
//        assertContainsTransition(t, s1, e1)
//    }

    func testActionsDispatchDynamically() {
        class Base { func test() { XCTFail() } }
        class Sub: Base { override func test() {} }

        let t = s1 | e1 | s2 | Sub().test
        t.transitions.first?.actions.first?()
    }
}

final class EnumTransitionTests: UnsafeTests {
    override var s1: ASP { S.one }
    override var s2: ASP { S.two }
    override var s3: ASP { S.three }

    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }

    enum S: SP { case one, two, three }
    enum E: EP { case one, two, three }
}

final class EnumValueTransitionTestsOne: UnsafeTests {
    override var s1: ASP { S.one("") }
    override var s2: ASP { S.two("") }
    override var s3: ASP { S.three("") }

    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }

    enum S: SP { case one(String), two(String), three(String) }
    enum E: EP { case one, two, three }
}

final class EnumValueTransitionTestsTwo: UnsafeTests {
    override var s1: ASP { S.one("1") }
    override var s2: ASP { S.one("2") }
    override var s3: ASP { S.one("3") }

    override var e1: AEP { E.one }
    override var e2: AEP { E.two }
    override var e3: AEP { E.three }

    enum S: SP { case one(String), two(String), three(String) }
    enum E: EP { case one, two, three }
}

final class StructTransitionTests: UnsafeTests {
    override var s1: ASP { S1() }
    override var s2: ASP { S2() }
    override var s3: ASP { S3() }

    override var e1: AEP { E1() }
    override var e2: AEP { E2() }
    override var e3: AEP { E3() }

    struct S1: SP {}; struct S2: SP {}; struct S3: SP {}
    struct E1: EP {}; struct E2: EP {}; struct E3: EP {}
}

protocol EqHa where Self: Hashable { }
extension EqHa {
    static func == (lhs: Self, rhs: Self) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }

    func hash(into hasher: inout Hasher) { }
}

final class ClassTransitionTests: UnsafeTests {
    override var s1: ASP { S1() }
    override var s2: ASP { S2() }
    override var s3: ASP { S3() }

    override var e1: AEP { E1() }
    override var e2: AEP { E2() }
    override var e3: AEP { E3() }

    class S1: SP, EqHa {}; class S2: SP, EqHa {}; class S3: SP, EqHa {}
    class E1: EP, EqHa {}; class E2: EP, EqHa {}; class E3: EP, EqHa {}
}

final class StringIntTransitionTests: UnsafeTests {
    override var s1: ASP { "s1" }
    override var s2: ASP { "s2" }
    override var s3: ASP { "s3" }

    override var e1: AEP { 1 }
    override var e2: AEP { 2 }
    override var e3: AEP { 3 }
}

final class MixedMessTests: UnsafeTests {
    override var s1: ASP { "s1" }
    override var s2: ASP { 2 }
    override var s3: ASP { false }

    override var e1: AEP { 1 }
    override var e2: AEP { "e2" }
    override var e3: AEP { true }
}

private protocol NeverEqual { }
extension NeverEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { false }
}

private protocol AlwaysEqual { }
extension AlwaysEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

final class ErasedHashableConformanceTests: XCTestCase {
    struct NeverEqualState: StateProtocol, NeverEqual { }
    struct AlwaysEqualState: StateProtocol, AlwaysEqual { }
    struct NeverEqualEvent: EventProtocol, NeverEqual { }
    struct AlwaysEqualEvent: EventProtocol, AlwaysEqual { }

    func testStateInequality() {
        let s1 = NeverEqualState().erase
        let s2 = NeverEqualState().erase

        XCTAssertNotEqual(s1, s2)
    }

    func testStateEquality() {
        let s1 = AlwaysEqualState().erase
        let s2 = AlwaysEqualState().erase

        XCTAssertEqual(s1, s2)
    }

    func testEventInequality() {
        let e1 = NeverEqualEvent().erase
        let e2 = NeverEqualEvent().erase

        XCTAssertNotEqual(e1, e2)
    }

    func testEventEquality() {
        let e1 = AlwaysEqualEvent().erase
        let e2 = AlwaysEqualEvent().erase

        XCTAssertEqual(e1, e2)
    }

    func testStateFalseSet() {
        let s1 = NeverEqualState().erase
        let s2 = NeverEqualState().erase

        XCTAssertEqual(2, Set([s1, s2]).count)
    }

    func testStateTrueSet() {
        let s1 = AlwaysEqualState().erase
        let s2 = AlwaysEqualState().erase

        XCTAssertEqual(1, Set([s1, s2]).count)
    }

    func testEventFalseSet() {
        let e1 = NeverEqualEvent().erase
        let e2 = NeverEqualEvent().erase

        XCTAssertEqual(2, Set([e1, e2]).count)
    }

    func testEventTrueSet() {
        let e1 = AlwaysEqualEvent().erase
        let e2 = AlwaysEqualEvent().erase

        XCTAssertEqual(1, Set([e1, e2]).count)
    }

    func testStateDictionaryLookup() {
        let s1 = AlwaysEqualEvent().erase
        let s2 = NeverEqualEvent().erase

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
        let wrapper = StateSpy() { e.fulfill() }.erase
        let _ = [wrapper: "Pass"]
        waitForExpectations(timeout: 0.1)
    }
}
