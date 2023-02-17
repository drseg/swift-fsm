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
        XCTAssertTrue(predicates.contains(expected),
                      "\(predicates)",
                      line: line)
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
    
    func testSinglePredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSinglePredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                action(e.fulfill) {
                    predicate(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSinglePredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSinglePredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    predicate(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSinglePredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testSinglePredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    predicate(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, tr: tr)
            assertContains(.locked, .pass, .locked, .a, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a, .b) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                action(e.fulfill) {
                    predicate(.a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate(.a, .b) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    predicate(.a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate(.a, .b) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testMultiPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    predicate(.a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
        
    func testArrayPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate([.a, .b]) {
                    actions(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill) {
                    predicate([.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate([.a, .b]) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    predicate([.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                predicate([.a, .b]) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testArrayPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    predicate([.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr)
            assertContains(.locked, .pass, .locked, .a, .b, tr: tr)
            
            tr.transitions.map(\.actions).flatten.executeAll()
        }
    }
    
    func testThenWithNoArgument() {
        let t1: Then = then()
        let t2: TAPRow = then()
        
        XCTAssertNil(t1.state)
        XCTAssertNil(t2.tap.state)
        XCTAssertTrue(t2.tap.actions.isEmpty)
        XCTAssertTrue(t2.tap.predicates.isEmpty)
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
    
    func testMultiWhenContext() {
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
    
    func testArrayWhenContext() {
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
    
    func testWhenPlusSinglePredicateInside() {
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
    
    func testWhenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    when(.coin) {
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
    
    func testWhenPlusMultiplePredicatesInside() {
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
    
    func testWhenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a, .b) {
                    when(.coin) {
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
    
    func testWhenPlusArrayPredicatesInside() {
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
    
    func testWhenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate([.a, .b]) {
                    when(.coin) {
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
    
    func testWhenActionCombinations() {
        let l1 = #line; let wap1 = when(.reset)          | { }
        let l2 = #line; let wap2 = when(.reset, .pass)   | { }
        let l3 = #line; let wap3 = when([.reset, .pass]) | [{ }]
        
        let l4 = #line; let wap4 = when(.reset)
        let l5 = #line; let wap5 = when(.reset, .pass)
        let l6 = #line; let wap6 = when([.reset, .pass])
        
        let all = [wap1, wap2, wap3, wap4, wap5, wap6]
        let allLines = [l1, l2, l3, l4, l5, l6]
        
        all.prefix(3).forEach {
            XCTAssertEqual($0.wap.actions.count, 1)
        }
        
        all.suffix(3).forEach {
            XCTAssertEqual($0.wap.actions.count, 0)
        }
        
        zip(all, allLines).forEach {
            XCTAssertEqual($0.0.wap.file, #file)
            XCTAssertEqual($0.0.wap.line, $0.1)
        }
        
        [wap1, wap4].map(\.wap).map(\.events).forEach {
            XCTAssertEqual($0, [.reset])
        }
        
        [wap2, wap3, wap5, wap6].map(\.wap).map(\.events).forEach {
            XCTAssertEqual($0, [.reset, .pass])
        }
    }
    
    func testThenContext() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    when(.reset) | e.fulfill
                    when(.pass)  | e.fulfill
                }
            }
            
            assertContains(.locked, .reset, .alarming, tr)
            assertContains(.locked, .pass, .alarming, tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    predicate(.a) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    predicate(.a, .b) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a, .b) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    predicate([.a, .b]) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate([.a, .b]) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
        }
    }
    
    func testThenPlusSinglePredicateInsideAndOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                predicate(.a) {
                    then(.alarming) {
                        predicate(.b) {
                            when(.reset) | e.fulfill
                            when(.pass)  | e.fulfill
                        }
                    }
                }
            }
            
            assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
            assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
            assertCount(2, tr)

            tr.transitions[0].actions[0]()
            tr.transitions[1].actions[0]()
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

