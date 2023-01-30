//
//  SittingFSMTests.swift
//  SittingTests
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

extension String: StateProtocol {}
extension Int: EventProtocol {}

class GenericTests: XCTestCase {
    enum State { case a, b, c, d, e, f }
    enum Event { case g, h, i, j, k, l }
    
    typealias Given = Generic.Given<State>
    typealias When = Generic.When<Event>
    typealias Then = Generic.Then<State>
    typealias Action = Generic.Action
    
    func transition<State, Event>(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ action: @escaping () -> Void = { }
    ) -> Transition<State, Event> {
        Transition(givenState: given,
                   event: when,
                   nextState: then,
                   action: action)
    }
    
    func assertFirst<State, Event>(
        _ expected: Transition<State, Event>,
        _ t: [Transition<State, Event>],
        line: UInt = #line
    ) {
        XCTAssertEqual(t.first, expected, line: line)
    }
    
    func assertLast<State, Event>(
        _ expected: Transition<State, Event>,
        _ t: [Transition<State, Event>],
        line: UInt = #line
    ) {
        XCTAssertEqual(t.last, expected, line: line)
    }
    
    func assertCount<State, Event>(
        _ expected: Int,
        _ t: [Transition<State, Event>],
        line: UInt = #line) {
        XCTAssertEqual(t.count, expected, line: line)
    }
}

final class GenericTransitionTests: GenericTests {
    func testSimpleConstructor() {
        let t = Given(.a) | When(.g) | Then(.b) | Action { }
        
        assertFirst(transition(.a, .g, .b), t)
    }
    
    func testSimpleLabellessConstructor() {
        let t = "s1" | 1 | "s2" | {}
        
        assertFirst(transition("s1", 1, "s2"), t)
    }

    func testMultiGivenConstructor() {
        let t = Given(.a, .b) | When(.g) | Then(.b) | Action { }
        
        assertFirst(transition(.a, .g, .b), t)
        assertLast(transition(.b, .g, .b), t)
        assertCount(2, t)
    }
    
    func testMultiGivenLabellessConstructor() {
        let t = ["s1", "s2"] | 1 | "s3" | {}

        assertFirst(transition("s1", 1, "s3"), t)
        assertLast(transition("s2", 1, "s3"), t)
        assertCount(2, t)
    }
    
    func testMultiWhenThenActionConstructor() {
        let t = Given(.a) | [When(.g) | Then(.b) | Action { },
                             When(.h) | Then(.c) | Action { }]
        
        assertFirst(transition(.a, .g, .b), t)
        assertLast(transition(.a, .h, .c), t)
        assertCount(2, t)
    }
    
    func testMultiWhenThenActionLabellessConstructor() {
#warning("Swift can't type check this all in one")
        let wta1 = 1 | "s2" | {}
        let wta2 = 2 | "s3" | {}
        
        let t = "s1" | [wta1,
                        wta2]

        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s1", 2, "s3"), t)
        assertCount(2, t)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        let t = Given(.a, .b) | [When(.g) | Then(.c) | Action { },
                                 When(.h) | Then(.c) | Action { }]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .h, .c), t)
        assertCount(4, t)
    }
    
    func testCombineMultiGivenMultiWhenThenLabelless() {
#warning("Swift can't type check this all in one")
        let wta1 = 1 | "s2" | {}
        let wta2 = 2 | "s3" | {}
        
        let t = ["s1",
                 "s2"] | [wta1,
                          wta2]

        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s2", 2, "s3"), t)
        assertCount(4, t)
    }
    
    func testMultiWhenConstructor() {
        let t = Given(.a) | When(.g, .h) | Then(.c) | Action { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.a, .h, .c), t)
        assertCount(2, t)
    }
    
    func testMultiWhenConstructorLabelless() {
        let t = "s1" | [1, 2] | "s2" | {}

        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s1", 2, "s2"), t)
        assertCount(2, t)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        let t = Given(.a, .b) | When(.g, .h) | Then(.c) | Action { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .h, .c), t)
        assertCount(4, t)
    }
    
    func testMultiGivenWhenConstructorLabelless() {
        let t = ["s1", "s2"] | [1, 2] | "s2" | {}

        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s2", 2, "s2"), t)
        assertCount(4, t)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        let t = Given(.a, .b) | [
            When(.g, .h) | Then(.c) | Action { },
            When(.i, .j) | Then(.d) | Action { }
        ]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .j, .d), t)
        assertCount(8, t)
    }
    
    func testCombineMultiGivenWhenConstructorLabelless() {
#warning("Swift can't type check this all in one")
        let wtas = [1, 2] | "s2" | {}
        let t = ["s1", "s2"] | wtas

        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s2", 2, "s2"), t)
        assertCount(4, t)
    }
    
    func testMultiWhenThenConstructor() {
        let t = Given(.a) | [When(.g) | Then(.c),
                             When(.h) | Then(.d)] | Action { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.a, .h, .d), t)
        assertCount(2, t)
    }
    
    func testMultiWhenThenConstructorLabelless() {
#warning("Swift can't type check this all in one")
        let wts = [1 | "s2",
                   2 | "s3"]
        let t = "s1" | wts | {}
        
        assertFirst(transition("s1", 1, "s2"), t)
        assertLast(transition("s1", 2, "s3"), t)
        assertCount(2, t)
    }
    
    func testMaxConstructors() {
        let t = Given(.a, .b) | [[When(.g, .h) | Then(.c),
                                  When(.h, .i) | Then(.d)] | Action { },
                                 
                                 [When(.i, .j) | Then(.e),
                                  When(.j, .k) | Then(.f)] | Action { }]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .k, .f), t)
        assertCount(16, t)
    }
    
    func testMaxConstructorsLabelless() {
        // do you dare?!
    }
    
    func testEquality() {
        let x = Given(.a, .b) | When(.g) | Then(.c) | Action { }
        var y = Given(.a, .b) | When(.g) | Then(.c) | Action { }
        XCTAssertEqual(x, y)

        y =     Given(.a, .a) | When(.g) | Then(.c) | Action { }
        XCTAssertNotEqual(x, y)

        y =     Given(.a, .b) | When(.h) | Then(.c) | Action { }
        XCTAssertNotEqual(x, y)

        y =     Given(.a, .b) | When(.g) | Then(.b)   | Action { }
        XCTAssertNotEqual(x, y)
    }

    func testBuilder() {
        let t = Transition.build {
            Given(.a, .b) | When(.g) | Then(.c) | Action { }
            Given(.c)     | When(.h) | Then(.d) | Action { }
            Given(.d)     | When(.i) | Then(.e) | Action { }
            Given(.e)     | When(.j) | Then(.f) | Action { }
        }

        XCTAssertEqual(t.count, 5)
    }

    func testBuilderDoesNotDuplicate() {
        let t = Transition.build {
            Given(.a, .a) | When(.g) | Then(.b) | Action { }
            Given(.a)     | When(.g) | Then(.b) | Action { }
        }

        XCTAssertEqual(t.count, 1)
    }

    func assertAction(_ e: XCTestExpectation) {
        e.fulfill()
    }

    func testActionPassedCorrectly() {
        let e = expectation(description: "passAction")
        let t = Given(.a) | When(.g) | Then(.c) | Action {
            self.assertAction(e)
        }
        t.first?.action()
        waitForExpectations(timeout: 0.1)
    }
    
    func testCanRetrieveTransitionByKey() {
        let ts = Transition.build {
            Given(.a, .b) | When(.g, .h) | Then(.b) | Action { }
        }
                
        let expectedT = ts[Transition.Key(state: .a, event: .h)]
        let nilT = ts[Transition.Key(state: .c, event: .h)]
        
        XCTAssertEqual(expectedT, transition(.a, .h, .b))
        XCTAssertNil(nilT)
    }
    
    func testBuilderIf() {
        let condition = true
        let ts = Transition.build {
            if(condition) {
                Given(.a) | When(.g) | Then(.b) | Action { }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
    
    func testBuilderElse() {
        let test = false
        let ts = Transition.build {
            if(test) {
                Given(.a) | When(.g) | Then(.b) | Action { }
                Given(.a) | When(.h) | Then(.b) | Action { }
            } else {
                Given(.b) | When(.i) | Then(.b) | Action { }
            }
        }
        XCTAssertEqual(ts.count, 1)
        XCTAssertEqual(ts.first?.value, transition(.b, .i, .b))
    }
    
    func testBuilderSwitch() {
        enum Switchy { case on, off }
        
        let state = Switchy.on
        let ts = Transition.build {
            switch state {
            case .on:  Given(.a) | When(.g) | Then(.b) | Action { }
            case .off: Given(.b) | When(.i) | Then(.b) | Action { }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
}
