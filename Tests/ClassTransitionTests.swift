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
    
    func testNesting() {
        t = [s2,
             s1] | [e1,
                    e2] | s2 | action
        
        assertFirst(transition(s2, e1, s2))
        assertLast(transition(s1, e2, s2))
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
    
    
    //    func testSimpleLabellessConstructor() {
    //        let t = "s1" | 1 | "s2" | {}
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //    }
    
    //    func testMultiGivenLabellessConstructor() {
    //        let t = ["s1", "s2"] | 1 | "s3" | {}
    //
    //        assertFirst(transition("s1", 1, "s3"), t)
    //        assertLast(transition("s2", 1, "s3"), t)
    //        assertCount(2, t)
    //    }
    
    //    func testMultiWhenThenActionLabellessConstructor() {
    //#warning("Swift can't type check this all in one")
    //        let wta1 = 1 | "s2" | {}
    //        let wta2 = 2 | "s3" | {}
    //
    //        let t = "s1" | [wta1,
    //                        wta2]
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //        assertLast(transition("s1", 2, "s3"), t)
    //        assertCount(2, t)
    //    }
    
    //    func testCombineMultiGivenMultiWhenThenLabelless() {
    //#warning("Swift can't type check this all in one")
    //        let wta1 = 1 | "s2" | {}
    //        let wta2 = 2 | "s3" | {}
    //
    //        let t = ["s1",
    //                 "s2"] | [wta1,
    //                          wta2]
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //        assertLast(transition("s2", 2, "s3"), t)
    //        assertCount(4, t)
    //    }
    
    //    func testMultiGivenWhenConstructorLabelless() {
    //        let t = ["s1", "s2"] | [1, 2] | "s2" | {}
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //        assertLast(transition("s2", 2, "s2"), t)
    //        assertCount(4, t)
    //    }
    
    //    func testCombineMultiGivenWhenConstructorLabelless() {
    //#warning("Swift can't type check this all in one")
    //        let wtas = [1, 2] | "s2" | {}
    //        let t = ["s1", "s2"] | wtas
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //        assertLast(transition("s2", 2, "s2"), t)
    //        assertCount(4, t)
    //    }
    
    //    func testMultiWhenThenConstructorLabelless() {
    //#warning("Swift can't type check this all in one")
    //        let wts = [1 | "s2",
    //                   2 | "s3"]
    //        let t = "s1" | wts | {}
    //
    //        assertFirst(transition("s1", 1, "s2"), t)
    //        assertLast(transition("s1", 2, "s3"), t)
    //        assertCount(2, t)
    //    }
    
    //    func testMaxConstructorsLabelless() {
    //        // do you dare?!
    //    }
}

final class UnsafeEnumTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S.one("").erased! }
    override var s2: ASP { S.two("").erased! }
    override var s3: ASP { S.three("").erased! }
    
    override var e1: AEP { E.one.erased! }
    override var e2: AEP { E.two.erased! }
    override var e3: AEP { E.three.erased! }
    
    enum S: State { case one(String), two(String), three(String) }
    enum E: Event { case one, two, three }
}

final class UnsafeStructTransitionTests: UnsafeTransitionTests {
    override var s1: ASP { S1().erased! }
    override var s2: ASP { S2().erased! }
    override var s3: ASP { S3().erased! }
    
    override var e1: AEP { E1().erased! }
    override var e2: AEP { E2().erased! }
    override var e3: AEP { E3().erased! }
    
    struct S1: State {}; struct S2: State {}; struct S3: State {}
    struct E1: Event {}; struct E2: Event {}; struct E3: Event {}
}

