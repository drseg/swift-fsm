import XCTest
@testable import FiniteStateMachine

enum P: PredicateProtocol { case a, b, c, d, e }

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
    
    func assertCount(
        _ c: Int,
        _ tr: TableRow<State, Event>,
        line: UInt = #line
    ) {
        XCTAssertEqual(c, tr.transitions.count, line: line)
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
    
    func testWithExpectation(
        count: Int = 1,
        line: UInt = #line,
        _ block: (XCTestExpectation) -> ()
    ) {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = count
        block(e)
        waitForExpectations(timeout: 0.1) { e in
            if let e {
                XCTFail(e.localizedDescription, line: line)
            }
        }
    }
    
    func testPredicateContext() {
        testWithExpectation { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    predicate(.b, .c) {
                        predicate([.d, .e]) {
                            when(.coin) | then() | e.fulfill
                        }
                    }
                }
            }
            
            assertContains(.locked, .coin, .locked, .a, .b, .c, .d, .e, tr: tr)
            tr.firstActions[0]()
        }
    }
    
    func testActionNestedInPredicateContext() {
        testWithExpectation(count: 3) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                        when(.reset)
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            assertContains(.locked, .reset, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testActionsNestedInPredicateContext() {
        testWithExpectation(count: 6) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                        when(.reset)
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            assertContains(.locked, .reset, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayActionsNestedInPredicateContext() {
        testWithExpectation(count: 6) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                        when(.reset)
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            assertContains(.locked, .reset, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSingleWhenContext() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    then(.unlocked)
                    then()
                    then(.alarming) | e.fulfill
                    then()          | e.fulfill
                }
            }
            
            assertContains(.locked, .coin, .unlocked, tr)
            assertContains(.locked, .coin, .locked, tr)
            assertContains(.locked, .coin, .alarming, tr)
            assertCount(4, tr)
            
            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions[0]()
            tr[3].actions[0]()
        }
    }
    
    func testMultipleWhenContext() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                when(.coin, .pass) {
                    then(.unlocked)
                    then()
                    then(.unlocked) | e.fulfill
                    then()          | e.fulfill
                }
            }
            
            assertContains(.locked, .coin, .unlocked, tr)
            assertCount(8, tr)
            
            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions.first?()
            tr[3].actions.first?()
            
            tr[4].actions[0]()
            tr[5].actions[0]()
            tr[6].actions[0]()
            tr[7].actions[0]()
        }
    }
    
    func testWhenArrayContext() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                when([.coin, .pass]) {
                    then(.unlocked)
                    then()
                    then(.unlocked) | e.fulfill
                    then()          | e.fulfill
                }
            }
            
            assertContains(.locked, .coin, .unlocked, tr)
            assertCount(8, tr)

            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions.first?()
            tr[3].actions.first?()
            
            tr[4].actions[0]()
            tr[5].actions[0]()
            tr[6].actions[0]()
            tr[7].actions[0]()
        }
    }
    
    func testWhenPlusSinglePredicate() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    predicate(.a) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .coin, .alarming, .a, tr: tr)
            assertCount(4, tr)

            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions[0]()
            tr[3].actions[0]()
        }
    }
    
    func testWhenPlusPredicates() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    predicate(.a, .b) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .coin, .alarming, .a, .b, tr: tr)
            assertCount(4, tr)

            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions[0]()
            tr[3].actions[0]()
        }
    }
    
    func testWhenPlusArrayPredicates() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    predicate([.a, .b]) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .coin, .alarming, .a, .b, tr: tr)
            assertCount(4, tr)

            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions[0]()
            tr[3].actions[0]()
        }
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

