//
//  SittingFSMTests.swift
//  SittingTests
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

final class GenericTransitionTests: XCTestCase {
    enum State { case a, b, c, d, e, f }
    enum Event { case g, h, i, j, k, l }
    
    typealias Given = Generic.Given<State>
    typealias When = Generic.When<Event>
    typealias Then = Generic.Then<State>
    typealias Action = Generic.Action
    
    typealias Transition = Generic.Transition<State,Event>
    var t: [Transition] = []
    
    func transition(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ action: @escaping () -> Void = { }
    ) -> Transition {
        Transition(givenState: given,
                   event: when,
                   nextState: then,
                   action: action)
    }
    
    func assertFirst(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.first, expected, line: line)
    }
    
    func assertLast(_ expected: Transition, line: UInt = #line) {
        XCTAssertEqual(t.last, expected, line: line)
    }
    
    func assertCount(_ expected: Int, line: UInt = #line) {
        XCTAssertEqual(t.count, expected, line: line)
    }
    
    func testSimpleConstructor() {
        t = Given(.a) | When(.g) | Then(.b) | Action { }
        
        assertFirst(transition(.a, .g, .b))
    }

    func testMultiGivenConstructor() {
        t = Given(.a, .b) | When(.g) | Then(.b) | Action { }
        
        assertFirst(transition(.a, .g, .b))
        assertLast(transition(.b, .g, .b))
        assertCount(2)
    }
    
    func testMultiWhenThenActionConstructor() {
        t = Given(.a) | [When(.g) | Then(.b) | Action { },
                         When(.h) | Then(.c) | Action { }]
        
        assertFirst(transition(.a, .g, .b))
        assertLast(transition(.a, .h, .c))
        assertCount(2)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        t = Given(.a, .b) | [When(.g) | Then(.c) | Action { },
                             When(.h) | Then(.c) | Action { }]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .h, .c))
        assertCount(4)
    }
    
    func testMultiWhenConstructor() {
        t = Given(.a) | When(.g, .h) | Then(.c) | Action { }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.a, .h, .c))
        assertCount(2)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        t = Given(.a, .b) | When(.g, .h) | Then(.c) | Action { }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .h, .c))
        assertCount(4)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        t = Given(.a, .b) | [
            When(.g, .h) | Then(.c) | Action { },
            When(.i, .j) | Then(.d) | Action { }
        ]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .j, .d))
        assertCount(8)
    }
    
    func testMultiWhenThenConstructor() {
        t = Given(.a) | [When(.g) | Then(.c),
                         When(.h) | Then(.d)] | Action { }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.a, .h, .d))
        assertCount(2)
    }
    
    func testMaxConstructors() {
        t = Given(.a, .b) | [[When(.g, .h) | Then(.c),
                              When(.h, .i) | Then(.d)] | Action { },
                             
                             [When(.i, .j) | Then(.e),
                              When(.j, .k) | Then(.f)] | Action { }]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .k, .f))
        assertCount(16)
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
                
        let expectedT = ts[Transition.Key(given: .a, event: .h)]
        let nilT = ts[Transition.Key(given: .c, event: .h)]
        
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
