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
        assertContains(g, w, t, p, tr, line)
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
        let predicates = tr.transitions.map(\.predicates).map(Set.init)
        let expected = Set(p.erased)
        XCTAssertTrue(predicates.contains(expected), "\(predicates)", line: line)
    }
    
    func testPredicateContext() {
        let tr =
        define(.locked) {
            predicate(.true) {
                predicate(.false) {
                    when(.coin) | ()
                }
            }
        }
        
        assertContains(.locked, .coin, .locked, .true, .false, tr: tr)
    }
    
    func testActionNestedInPredicateContext() {
        let e = expectation(description: "action")
        let tr =
        define(.locked) {
            predicate(.true, .false) {
                action(e.fulfill) {
                    when(.coin) | then(.locked)
                }
            }
        }
        
        assertContains(.locked, .coin, .locked, .true, .false, tr: tr)
        tr.firstActions[0]()
        waitForExpectations(timeout: 0.1)
    }
    
    func testWhenContext() {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = 8
        
        let tr =
        define(.locked) {
            when(.coin, .pass) {
                then(.unlocked)
                then()
                then(.unlocked) | e.fulfill
                then()          | e.fulfill
                
                predicate(.true) {
                    then(.alarming)
                    then()
                    then(.alarming) | e.fulfill
                    then()          | e.fulfill
                }
            }
        }
        
        assertContains(.locked, .coin, .unlocked, tr)
        assertContains(.locked, .pass, .locked, tr)
        assertContains(.locked, .coin, .alarming, .true, tr: tr)
        assertContains(.locked, .coin, .locked, .true, tr: tr)

        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions.first?()
        tr[3].actions.first?()
        
        tr[4].actions[0]()
        tr[5].actions[0]()
        tr[6].actions[0]()
        tr[7].actions[0]()
        
        tr[8].actions.first?()
        tr[9].actions.first?()
        tr[10].actions.first?()
        tr[11].actions.first?()
        
        tr[12].actions[0]()
        tr[13].actions[0]()
        tr[14].actions[0]()
        tr[15].actions[0]()
        
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
                        [P1.b, P2.h, P3.y]].asSetofSets
        
        XCTAssertEqual(expected, states.uniquePermutationsOfElementCases)
    }
}

extension Array where Element == [any PredicateProtocol] {
    var asSetofSets: Set<Set<AnyPredicate>> {
        map { $0.erased.asSet }.asSet
    }
}

extension Array where Element: Hashable {
    var asSet: Set<Self.Element> {
        Set(self)
    }
}

