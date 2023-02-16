import XCTest
@testable import FiniteStateMachine

enum P: PredicateProtocol { case `true`, `false` }

final class ComplexTransitionBuilderTests:
    TestingBase, ComplexTransitionBuilder
{
    typealias Predicate = P
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ p: Predicate...,
        tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains(g, w, t, p, tr)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ p: [Predicate] = [],
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains(g, w, t, tr, line)
        XCTAssertEqual(Set(p.erased), Set(tr.firstPredicates), line: line)
    }
    
    func testPredicateContext() {
        let tr = define(.locked) {
            context(.true) {
                context(.false) {
                    when(.coin) | ()
                }
            }
        }
        
        assertContains(.locked, .coin, .locked, .true, .false, tr: tr)
    }
    
    func testWhenContext() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 2
        let tr = define(.locked) {
            context(.coin) {
                then(.unlocked) | e.fulfill
                then()          | e.fulfill
                then(.alarming)
            }
        }
        
        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .coin, .locked, tr)
        assertContains(.locked, .coin, .alarming, tr)

        tr[0].actions[0]()
        tr[1].actions[0]()
        tr[2].actions.first?()
        waitForExpectations(timeout: 0.1)
    }
    
    func testActionNestedInPredicateContext() {
        let e = expectation(description: "action")
        let tr = define(.locked) {
            context(.true, .false) {
                context(e.fulfill) {
                    when(.coin) | then(.locked)
                }
            }
        }
        
        assertContains(.locked, .coin, .locked, .true, .false, tr: tr)
        tr.firstActions[0]()
        waitForExpectations(timeout: 0.1)
    }
}

extension Array where Element == P {
    var erased: [AnyPredicate] {
        map(\.erased)
    }
}

extension TableRow {
    subscript(index: Int) -> Transition<S, E> {
        transitions[index]
    }
    
    var firstActions: [() -> ()] {
        transitions.first?.actions ?? []
    }
    
    var firstPredicates: [AnyPredicate] {
        transitions.first?.predicates ?? []
    }
}

final class CharacterisationTests: XCTestCase {
    enum P1: PredicateProtocol { case a, b }
    enum P2: PredicateProtocol { case g, h }
    enum P3: PredicateProtocol { case x, y }
    
    func testPermutations() {
        let states: [any PredicateProtocol] = [P2.g,
                                               P2.h,
                                               P1.a,
                                               P1.b,
                                               P3.y]
        
        let expected = [[P1.a, P2.g, P3.x],
                        [P1.b, P2.g, P3.x],
                        [P1.a, P2.g, P3.y],
                        [P1.b, P2.g, P3.y],
                        [P1.a, P2.h, P3.x],
                        [P1.b, P2.h, P3.x],
                        [P1.a, P2.h, P3.y],
                        [P1.b, P2.h, P3.y]].s
        
        XCTAssertEqual(expected, states.uniquePermutationsOfElementCases)
    }
}

extension Array where Element == [any PredicateProtocol] {
    var s: Set<Set<AnyPredicate>> {
        map { $0.erased.s }.s
    }
}

extension Array where Element: Hashable {
    var s: Set<Self.Element> {
        Set(self)
    }
}

