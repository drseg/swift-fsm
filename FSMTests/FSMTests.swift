//
//  SittingFSMTests.swift
//  SittingTests
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

final class FSMTests: XCTestCase {
    enum State { case a, b, c, d, e, f }
    enum Event { case g, h, i, j, k, l }
    
    typealias Given = FiniteStateMachine.Given<State>
    typealias When = FiniteStateMachine.When<Event>
    typealias Then = FiniteStateMachine.Then<State>
    typealias Action = FiniteStateMachine.Action<FSMTests>
    
    typealias Transition = FiniteStateMachine.Transition<State,Event,State,FSMTests>
    
    var t: [Transition] = []
    
    func transition(
        _ given: State,
        _ when: Event,
        _ then: State,
        _ action: @escaping (FSMTests) -> Void = { _ in }
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
        t = Given(.a) | When(.g) | Then(.b) | Action { _ in }
        
        assertFirst(transition(.a, .g, .b))
    }

    func testMultiGivenConstructor() {
        t = Given(.a, .b) | When(.g) | Then(.b) | Action { _ in }
        
        assertFirst(transition(.a, .g, .b))
        assertLast(transition(.b, .g, .b))
        assertCount(2)
    }
    
    func testMultiWhenThenActionConstructor() {
        t = Given(.a) | [When(.g) | Then(.b) | Action { _ in },
                         When(.h) | Then(.c) | Action { _ in }]
        
        assertFirst(transition(.a, .g, .b))
        assertLast(transition(.a, .h, .c))
        assertCount(2)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        t = Given(.a, .b) | [When(.g) | Then(.c) | Action { _ in },
                             When(.h) | Then(.c) | Action { _ in }]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .h, .c))
        assertCount(4)
    }
    
    func testMultiWhenConstructor() {
        t = Given(.a) | When(.g, .h) | Then(.c) | Action { _ in }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.a, .h, .c))
        assertCount(2)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        t = Given(.a, .b) | When(.g, .h) | Then(.c) | Action { _ in }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .h, .c))
        assertCount(4)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        t = Given(.a, .b) | [
            When(.g, .h) | Then(.c) | Action { _ in },
            When(.i, .j) | Then(.d) | Action { _ in }
        ]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .j, .d))
        assertCount(8)
    }
    
    func testMultiWhenThenConstructor() {
        t = Given(.a) | [When(.g) | Then(.c),
                         When(.h) | Then(.d)] | Action { _ in }
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.a, .h, .d))
        assertCount(2)
    }
    
    func testMaxConstructors() {
        t = Given(.a, .b) | [[When(.g, .h) | Then(.c),
                              When(.h, .i) | Then(.d)] | Action { _ in },
                             
                             [When(.i, .j) | Then(.e),
                              When(.j, .k) | Then(.f)] | Action { _ in }]
        
        assertFirst(transition(.a, .g, .c))
        assertLast(transition(.b, .k, .f))
        assertCount(16)
    }
    
    func testEquality() {
        let x = Given(.a, .b) | When(.g) | Then(.c) | Action { _ in }
        var y = Given(.a, .b) | When(.g) | Then(.c) | Action { _ in }
        XCTAssertEqual(x, y)

        y =     Given(.a, .a) | When(.g) | Then(.c) | Action { _ in }
        XCTAssertNotEqual(x, y)

        y =     Given(.a, .b) | When(.h) | Then(.c) | Action { _ in }
        XCTAssertNotEqual(x, y)

        y =     Given(.a, .b) | When(.g) | Then(.b)   | Action { _ in }
        XCTAssertNotEqual(x, y)
    }

    func testBuilder() {
        let t = Transition.build {
            Given(.a, .b) | When(.g) | Then(.c) | Action { _ in }
            Given(.c)     | When(.h) | Then(.d) | Action { _ in }
            Given(.d)     | When(.i) | Then(.e) | Action { _ in }
            Given(.e)     | When(.j) | Then(.f) | Action { _ in }
        }

        XCTAssertEqual(t.count, 5)
    }

    func testBuilderDoesNotDuplicate() {
        let t = Transition.build {
            Given(.a, .a) | When(.g) | Then(.b) | Action { _ in }
            Given(.a)     | When(.g) | Then(.b) | Action { _ in }
        }

        XCTAssertEqual(t.count, 1)
    }

    func assertAction(_ e: XCTestExpectation) {
        e.fulfill()
    }

    func testActionPassedCorrectly() {
        let e = expectation(description: "passAction")
        let t = Given(.a) | When(.g) | Then(.c) | Action {
            $0.assertAction(e)
        }
        t.first?.action(self)
        waitForExpectations(timeout: 0.1)
    }
    
    func testCanRetrieveTransitionByKey() {
        let ts = Transition.build {
            Given(.a, .b) | When(.g, .h) | Then(.b) | Action { _ in }
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
                Given(.a) | When(.g) | Then(.b) | Action { _ in }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
    
    func testBuilderElse() {
        let test = false
        let ts = Transition.build {
            if(test) {
                Given(.a) | When(.g) | Then(.b) | Action { _ in }
                Given(.a) | When(.h) | Then(.b) | Action { _ in }
            } else {
                Given(.b) | When(.i) | Then(.b) | Action { _ in }
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
            case .on:  Given(.a) | When(.g) | Then(.b) | Action { _ in }
            case .off: Given(.b) | When(.i) | Then(.b) | Action { _ in }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
}
