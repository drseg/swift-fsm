//
//  SittingFSMTests.swift
//  SittingTests
//
//  Created by Daniel Segall on 28/01/2023.
//

import XCTest
@testable import FiniteStateMachine

class SafeTests: XCTestCase {
    enum State { case a, b, c, d, e, f }
    enum Event { case g, h, i, j, k, l }
    
    typealias G = Safe.Given<State>
    typealias W = Safe.When<Event>
    typealias T = Safe.Then<State>
    typealias A = Safe.Action
        
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

final class SafeTransitionTests: SafeTests {
    func testSimpleConstructor() {
        let t = G(.a) | W(.g) | T(.b) | A { }
        
        assertFirst(transition(.a, .g, .b), t)
    }
    
    func testMultiGivenConstructor() {
        let t = G(.a, .b) | W(.g) | T(.b) | A { }
        
        assertFirst(transition(.a, .g, .b), t)
        assertLast(transition(.b, .g, .b), t)
        assertCount(2, t)
    }
    
    func testMultiWhenThenActionConstructor() {
        let t = G(.a) | [W(.g) | T(.b) | A { },
                         W(.h) | T(.c) | A { }]
        
        assertFirst(transition(.a, .g, .b), t)
        assertLast(transition(.a, .h, .c), t)
        assertCount(2, t)
    }
    
    func testCombineMultiGivenAndMultiWhenThenAction() {
        let t = G(.a, .b) | [W(.g) | T(.c) | A { },
                             W(.h) | T(.c) | A { }]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .h, .c), t)
        assertCount(4, t)
    }
    
    func testMultiWhenConstructor() {
        let t = G(.a) | W(.g, .h) | T(.c) | A { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.a, .h, .c), t)
        assertCount(2, t)
    }
    
    func testMultiGivenMultiWhenConstructor() {
        let t = G(.a, .b) | W(.g, .h) | T(.c) | A { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .h, .c), t)
        assertCount(4, t)
    }
    
    func testCombineMultiGivenMultiWhenMultiWhenThenAction() {
        let t = G(.a, .b) | [
            W(.g, .h) | T(.c) | A { },
            W(.i, .j) | T(.d) | A { }
        ]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .j, .d), t)
        assertCount(8, t)
    }
    
    func testMultiWhenThenConstructor() {
        let t = G(.a) | [W(.g) | T(.c),
                         W(.h) | T(.d)] | A { }
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.a, .h, .d), t)
        assertCount(2, t)
    }
    
    func testMaxConstructors() {
        let t = G(.a, .b) | [[W(.g, .h) | T(.c),
                              W(.h, .i) | T(.d)] | A { },
                             
                             [W(.i, .j) | T(.e),
                              W(.j, .k) | T(.f)] | A { }]
        
        assertFirst(transition(.a, .g, .c), t)
        assertLast(transition(.b, .k, .f), t)
        assertCount(16, t)
    }
    
    func testEquality() {
        let x = G(.a, .b) | W(.g) | T(.c) | A { }
        var y = G(.a, .b) | W(.g) | T(.c) | A { }
        XCTAssertEqual(x, y)

        y =     G(.a, .a) | W(.g) | T(.c) | A { }
        XCTAssertNotEqual(x, y)

        y =     G(.a, .b) | W(.h) | T(.c) | A { }
        XCTAssertNotEqual(x, y)

        y =     G(.a, .b) | W(.g) | T(.b)   | A { }
        XCTAssertNotEqual(x, y)
    }

    func testBuilder() {
        let t = Transition.build {
            G(.a, .b) | W(.g) | T(.c) | A { }
            G(.c)     | W(.h) | T(.d) | A { }
            G(.d)     | W(.i) | T(.e) | A { }
            G(.e)     | W(.j) | T(.f) | A { }
        }

        XCTAssertEqual(t.count, 5)
    }
    
    func testGivenBuilder() {
        let t = G(.a, .b) {
            W(.h) | T(.b) | A {}
            W(.g) | T(.a) | {  }
        }
        
        XCTAssertEqual(t.count, 4)
    }
    
    func testGivenBuilderWithWhenThenArray() {
        let t = G(.a, .b) {
            [W(.h) | T(.b),
             W(.g) | T(.a)] | A {}
        }
        
        XCTAssertEqual(t.count, 4)
    }
    
    func testNestedBuilder() {
        let t = Transition.build {
            G(.a, .b) {
                [W(.h) | T(.b),
                 W(.g) | T(.a)] | A {}
            }
        }
        
        XCTAssertEqual(t.count, 4)
    }

    func testBuilderDoesNotDuplicate() {
        let t = Transition.build {
            G(.a, .a) | W(.g) | T(.b) | A { }
            G(.a)     | W(.g) | T(.b) | A { }
        }

        XCTAssertEqual(t.count, 1)
    }

    func assertAction(_ e: XCTestExpectation) {
        e.fulfill()
    }

    func testActionPassedCorrectly() {
        let e = expectation(description: "passAction")
        let t = G(.a) | W(.g) | T(.c) | A {
            self.assertAction(e)
        }
        t.first?.action()
        waitForExpectations(timeout: 0.1)
    }
    
    func testCanRetrieveTransitionByKey() {
        let ts = Transition.build {
            G(.a, .b) | W(.g, .h) | T(.b) | A { }
        }
                
        let expectedT = ts[Transition.Key(state: .a, event: .h)]
        let nilT = ts[Transition.Key(state: .c, event: .h)]
        
        XCTAssertEqual(expectedT, transition(.a, .h, .b))
        XCTAssertNil(nilT)
    }
    
    func testBuilderIfTrue() {
        let condition = true
        let ts = Transition.build {
            if condition {
                G(.a) | W(.g) | T(.b) | A { }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
    
    func testBuilderIfFalse() {
        let condition = false
        let ts = Transition.build {
            if condition {
                G(.a) | W(.g) | T(.b) | A { }
            }
        }
        XCTAssert(ts.isEmpty)
    }
    
    func testBuilderElse() {
        let test = false
        let ts = Transition.build {
            if test {
                G(.a) | W(.g) | T(.b) | A { }
                G(.a) | W(.h) | T(.b) | A { }
            } else {
                G(.b) | W(.i) | T(.b) | A { }
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
            case .on:  G(.a) | W(.g) | T(.b) | A { }
            case .off: G(.b) | W(.i) | T(.b) | A { }
            }
        }
        XCTAssertEqual(ts.first?.value, transition(.a, .g, .b))
    }
}
