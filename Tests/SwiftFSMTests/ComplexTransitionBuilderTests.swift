import XCTest
@testable import SwiftFSM

enum P: PredicateProtocol { case a, b, c, d, e }

final class ComplexTransitionBuilderTests:
    TestingBase, ComplexTransitionBuilder
{
    typealias Predicate = P
    typealias TR = TableRow<State, Event>
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ p: Predicate...,
        tr: TR,
        _ line: UInt = #line
    ) {
        assertContains(g, w, t, p, tr, line)
    }
    
    func assertCount(_ c: Int, _ tr: TR, line: UInt = #line) {
        XCTAssertEqual(c, tr.transitions.count, line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ p: [Predicate] = [],
        _ tr: TR,
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
                match(.a) {
                    match(any: .b, .c) {
                        match(any: [.d, .e]) {
                            when(.coin) | then() | e.fulfill
                        }
                    }
                }
            }
            
            assertContains(.locked, .coin, .locked, .a, .b, .c, .d, .e, tr: tr)
            tr.firstActions[0]()
        }
    }
    
    func assertSinglePredicateWithAction(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .coin, .unlocked, .a, tr: tr, line)
        assertContains(.locked, .pass, .locked, .a, tr: tr, line)
        
        tr.transitions.map(\.actions).flatten.executeAll()
    }
    
    func testSinglePredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func testSinglePredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                action(e.fulfill) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func testSinglePredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func testSinglePredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func testSinglePredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func testSinglePredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertSinglePredicateWithAction(tr)
        }
    }
    
    func assertMultiPredicateWithAction(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .coin, .unlocked, .a, .b, tr: tr, line)
        assertContains(.locked, .pass, .locked, .a, .b, tr: tr, line)
        
        tr.transitions.map(\.actions).flatten.executeAll()
    }
    
    func testMultiPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: .a, .b) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testMultiPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                action(e.fulfill) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testMultiPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(any: .a, .b) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testMultiPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testMultiPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(any: .a, .b) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testMultiPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
        
    func testArrayPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: [.a, .b]) {
                    actions(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testArrayPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testArrayPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(any: [.a, .b]) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testArrayPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions(e.fulfill, e.fulfill) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testArrayPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                match(any: [.a, .b]) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testArrayPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            let tr =
            define(.locked) {
                actions([e.fulfill, e.fulfill]) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
            
            assertMultiPredicateWithAction(tr)
        }
    }
    
    func testThenWithNoArgument() {
        let t1: Then = then()
        let t2: TAPRow = then()
        
        XCTAssertNil(t1.state)
        XCTAssertNil(t2.tap.state)
        XCTAssertTrue(t2.tap.actions.isEmpty)
        XCTAssertTrue(t2.tap.match.allOf.isEmpty)
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
    
    func assertMultiWhenContext(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .coin, .unlocked, tr, line)
        assertCount(8, tr, line: line)
        
        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions.first?()
        tr[3].actions.first?()
        
        tr[4].actions[0]()
        tr[5].actions[0]()
        tr[6].actions[0]()
        tr[7].actions[0]()
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
            
            assertMultiWhenContext(tr)
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
            
            assertMultiWhenContext(tr)
        }
    }
    
    func assertWhenPlusSinglePredicate(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .coin, .alarming, .a, tr: tr, line)
        assertCount(4, tr, line: line)

        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions[0]()
        tr[3].actions[0]()
    }
    
    func testWhenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    match(.a) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusSinglePredicate(tr)
        }
    }
    
    func testWhenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusSinglePredicate(tr)
        }
    }
    
    func assertWhenPlusMultiPredicate(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .coin, .alarming, .a, .b, tr: tr, line)
        assertCount(4, tr, line: line)

        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions[0]()
        tr[3].actions[0]()
    }
    
    func testWhenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    match(any: .a, .b) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusMultiPredicate(tr)
        }
    }
    
    func testWhenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: .a, .b) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusMultiPredicate(tr)
        }
    }
    
    func testWhenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin) {
                    match(any: [.a, .b]) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusMultiPredicate(tr)
        }
    }
    
    func testWhenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: [.a, .b]) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
            
            assertWhenPlusMultiPredicate(tr)
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
    
    func callActions(_ tr: TR) {
        tr.transitions[0].actions[0]()
        tr.transitions[1].actions[0]()
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

            callActions(tr)
        }
    }
    
    func assertThenPlusSinglePredicate(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .reset, .alarming, .a, tr: tr, line)
        assertContains(.locked, .pass, .alarming, .a, tr: tr, line)
        assertCount(2, tr, line: line)

        callActions(tr)
    }
    
    func testThenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    match(.a) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusSinglePredicate(tr)
        }
    }
    
    func testThenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusSinglePredicate(tr)
        }
    }
    
    func assertThenPlusMultiplePredicates(_ tr: TR, line: UInt = #line) {
        assertContains(.locked, .reset, .alarming, .a, .b, tr: tr)
        assertContains(.locked, .pass, .alarming, .a, .b, tr: tr)
        assertCount(2, tr)

        callActions(tr)
    }
    
    func testThenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    match(any: .a, .b) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusMultiplePredicates(tr)
        }
    }
    
    func testThenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: .a, .b) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusMultiplePredicates(tr)
        }
    }
    
    func testThenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                then(.alarming) {
                    match(any: [.a, .b]) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusMultiplePredicates(tr)
        }
    }
    
    func testThenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(any: [.a, .b]) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
            
            assertThenPlusMultiplePredicates(tr)
        }
    }
    
    func testThenPlusSinglePredicateInsideAndOutside() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                match(.a) {
                    then(.alarming) {
                        match(.b) {
                            when(.reset) | e.fulfill
                            when(.pass)  | e.fulfill
                        }
                    }
                }
            }
            
            assertThenPlusMultiplePredicates(tr)
        }
    }
}

final class MatcherTests: TestingBase {
    enum P: String, PredicateProtocol { case a, b }
    enum Q: String, PredicateProtocol { case a, b }
    enum R: String, PredicateProtocol { case a, b }
    
    func assertMatches(
        allOf: [any PredicateProtocol] = [],
        anyOf: [any PredicateProtocol] = [],
        adding a: [[any PredicateProtocol]] = [],
        equals expected: [[any PredicateProtocol]],
        line: UInt = #line
    ) {
        let match = Match(allOf: allOf, anyOf: anyOf)
        XCTAssertEqual(match.allMatches(a.map(\.erased).asSets),
                       expected.erasedSets,
                       line: line)
    }
    
    func testAllEmpty() {
        XCTAssertEqual(Match().allMatches([]), [])
    }
    
    func testEmptyMatcher() {
        assertMatches(equals: [])
    }
    
    func testAnyOfSinglePredicate() {
        assertMatches(anyOf: [P.a], equals: [[P.a]])
    }

    func testAnyOfMultiPredicate() {
        assertMatches(anyOf: [P.a, P.b], equals: [[P.a], [P.b]])
    }

    func testAllOfSingleType() {
        assertMatches(allOf: [P.a], equals: [[P.a]])
    }
    
    func testAllOfMultiTypeM() {
        assertMatches(allOf: [P.a, Q.a], equals: [[P.a, Q.a]])
    }
    
    func testCombinedAnyAndAll() {
        assertMatches(allOf: [P.a, Q.a],
                      anyOf: [R.a, R.b],
                      equals: [[P.a, Q.a, R.a],
                               [P.a, Q.a, R.b]])
    }
    
    func testEmptyMatcherWithSingleOther() {
        assertMatches(adding: [[P.a]],
                      equals: [[P.a]])
    }
    
    func testEmptyMatcherWithMultiOther() {
        assertMatches(adding: [[P.a, Q.a]],
                      equals: [[P.a, Q.a]])
    }
    
    func testEmptyMatcherWithMultiMultiOther() {
        assertMatches(adding: [[P.a, Q.a],
                               [P.a, Q.b]],
                      equals: [[P.a, Q.a],
                               [P.a, Q.b]])
    }
    
    func testAnyMatcherWithOther() {
        assertMatches(anyOf: [P.a, P.b],
                      adding: [[Q.a, R.a],
                               [Q.b, R.b]],
                      equals: [[P.a, Q.a, R.a],
                               [P.a, Q.b, R.b],
                               [P.b, Q.a, R.a],
                               [P.b, Q.b, R.b]])
    }
    
    func testAllMatcherWithOther() {
        assertMatches(allOf: [P.a, Q.a],
                      adding: [[R.a],
                               [R.b]],
                      equals: [[P.a, Q.a, R.a],
                               [P.a, Q.a, R.b]])
    }
}

extension Match {
    func allMatches(
        _ impliedPredicates: Set<Set<AnyPredicate>> = []
    ) -> Set<Set<AnyPredicate>> {
        func emptySet() -> Set<Set<AnyPredicate>> {
            Set(arrayLiteral: Set([AnyPredicate]()))
        }
        
        if anyOf.isEmpty {
            if impliedPredicates.isEmpty {
                return [allOf].asSets
            }
            
            return impliedPredicates.reduce(into: emptySet()) {
                $0.insert(Set($1 + allOf))
            }.flattenEmpties
        }
        
        let anyAndAll = anyOf.reduce(into: [[AnyPredicate]]()) {
            $0.append(allOf + [$1])
        }
        
        if impliedPredicates.isEmpty {
            return anyAndAll.asSets
        }
        
        return anyAndAll.reduce(into: emptySet()) { result, predicate in
            impliedPredicates.forEach { result.insert(Set(predicate + $0)) }
        }.flattenEmpties
    }
    
    func add(
        _ allCases: Set<Set<AnyPredicate>>,
        to ps: [[AnyPredicate]]
    ) -> Set<Set<AnyPredicate>> {
        ps.asSets.union(allCases).flattenEmpties
    }
    
    // first we need a list of all types not represented in either any or all
    // then we need the complete list of their permutations
    // for each of our existing anys, we need to create a new list of permutations:
    // for each permutation, add the single any, and all the alls
    // fsm.handleEvent has to throw if the predicate array count is unexpected
    // Match itself will have an isValid check that its alls and anys make sense
}

extension Collection
where Element: Collection, Element: Hashable, Element.Element: Hashable {
    var asSets: Set<Set<Element.Element>> {
        Set(map(Set.init)).flattenEmpties
    }
    
    var flattenEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}

extension Array where Element == P {
    var erased: [AnyPredicate] {
        map(\.erase)
    }
}

extension TableRow {
    subscript(index: Int) -> Transition<S, E> {
        transitions[index]
    }
    
    var firstActions: [() -> ()] {
        transitions.first?.actions ?? []
    }
}

final class CharacterisationTests: XCTestCase {
    enum P1: PredicateProtocol { case a, b }
    enum P2: PredicateProtocol { case g, h }
    enum P3: PredicateProtocol { case x, y }
    
    func testPermutations() {
        let predicates: [any PredicateProtocol] = [P2.g,
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
                        [P1.b, P2.h, P3.y]].erasedSets
        
        XCTAssertEqual(expected, predicates.uniquePermutationsOfAllCases)
    }
}

extension Array where Element == [any PredicateProtocol] {
    var erasedSets: Set<Set<AnyPredicate>> {
        Set(map { Set($0.erased) })
    }
}

