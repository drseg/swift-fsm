import XCTest
@testable import SwiftFSM

enum P: PredicateProtocol { case a, b, c, d, e }

final class ComplexTransitionBuilderTests:
    TestingBase, ComplexTransitionBuilder
{
    typealias Predicate = P
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ m: Match,
        tr: TR,
        _ file: StaticString = #file,
        _ line: UInt = #line
    ) {
        assertContains(g, w, t, m, tr, line)
    }
    
    func assertCount(
        _ c: Int,
        _ tr: TR,
        line: UInt = #line
    ) {
        XCTAssertEqual(c, tr.wtaps.count, line: line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains(g, [w], t, .none, tr, line)
    }
    
    func assertContains(
        _ g: State,
        _ w: Event,
        _ t: State,
        _ m: Match,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains(g, [w], t, m, tr, line)
    }
    
    func assertContains(
        _ g: State,
        _ w: [Event],
        _ t: State,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        assertContains(g, w, t, .none, tr, line)
    }
    
    func assertContains(
        _ g: State,
        _ w: [Event],
        _ t: State,
        _ m: Match = .none,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.wtaps.contains(
                WTAP(events: w,
                     state: t,
                     actions: [],
                     match: m,
                     file: #file,
                     line: #line)
            ),
            "\n(\(w), \(t), \(m)) \nnot found in: \n\(tr.description)",
            line: line)
        
        XCTAssertTrue(tr.givenStates.contains(g),
                      "\n'\(g)' not found in: \(tr.givenStates)",
                      line: line)
    }
    
    func testWithExpectation(
        count: Int = 1,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: (XCTestExpectation) -> ()
    ) {
        let e = expectation(description: "action")
        e.expectedFulfillmentCount = count
        block(e)
        waitForExpectations(timeout: 0.1) { e in
            if e != nil {
                XCTFail("Unfulfilled expectations", file: file, line: line)
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
                        
            let m = Match(anyOf: [P.a, P.b, P.c, P.d, P.e])
            assertContains(.locked, .coin, .locked, m, tr: tr)
            tr.wtaps.map(\.actions)[0][0]()
        }
    }
    
    func tableRow(_ block: () -> [WTAPRow<State, Event>]) -> TR {
        define(.locked) { block() }
    }

    func assertWithAction(
        _ m: Match,
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .coin, .unlocked, m, tr, line)
        assertContains(.locked, .pass, .locked, m, tr, line)
        assertCount(2, tr, line: line)

        tr.wtaps.map(\.actions).flatten.executeAll()
    }

    func assertSinglePredicateWithAction(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertWithAction(Match(anyOf: [P.a]), block, line: line)
    }

    func testSinglePredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertSinglePredicateWithAction {
                match(.a) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testSinglePredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            assertSinglePredicateWithAction {
                action(e.fulfill) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testSinglePredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            assertSinglePredicateWithAction {
                match(.a) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testSinglePredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertSinglePredicateWithAction {
                actions(e.fulfill, e.fulfill) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testSinglePredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            assertSinglePredicateWithAction {
                match(.a) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testSinglePredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertSinglePredicateWithAction {
                actions([e.fulfill, e.fulfill]) {
                    match(.a) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func assertMultiPredicateWithAction(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertWithAction(Match(anyOf: [P.a, P.b]), block, line: line)
    }

    func testMultiPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                match(any: .a, .b) {
                    action(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                action(e.fulfill) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(any: .a, .b) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill, e.fulfill) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testMultiPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(any: .a, .b) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testMultiPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions([e.fulfill, e.fulfill]) {
                    match(any: .a, .b) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                match(any: [.a, .b]) {
                    actions(e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(any: [.a, .b]) {
                    actions(e.fulfill, e.fulfill) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill, e.fulfill) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(any: [.a, .b]) {
                    actions([e.fulfill, e.fulfill]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
        }
    }

    func testArrayPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions([e.fulfill, e.fulfill]) {
                    match(any: [.a, .b]) {
                        when(.coin) | then(.unlocked)
                        when(.pass) | then()
                    }
                }
            }
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

    func assertMultiWhenContext(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, [.coin, .pass], .unlocked, tr, line)
        assertCount(4, tr, line: line)
        
        tr[0].actions.first?()
        tr[1].actions.first?()

        tr[2].actions[0]()
        tr[3].actions[0]()
    }

    func testMultiWhenContext() {
        testWithExpectation(count: 2) { e in
            assertMultiWhenContext {
                when(.coin, .pass) {
                    then(.unlocked)
                    then()
                    then(.unlocked) | e.fulfill
                    then()          | e.fulfill
                }
            }
        }
    }

    func testArrayWhenContext() {
        testWithExpectation(count: 2) { e in
            assertMultiWhenContext {
                when([.coin, .pass]) {
                    then(.unlocked)
                    then()
                    then(.unlocked) | e.fulfill
                    then()          | e.fulfill
                }
            }
        }
    }

    func assertWhen(
        _ m: Match = .none,
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .coin, .alarming, m, tr, line)
        assertCount(4, tr, line: line)

        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions[0]()
        tr[3].actions[0]()
    }

    func assertWhenPlusSinglePredicate(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertWhen(Match(anyOf: [P.a]), block, line: line)
    }

    func testWhenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusSinglePredicate {
                when(.coin) {
                    match(.a) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
        }
    }

    func testWhenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusSinglePredicate {
                match(.a) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
        }
    }

    func assertWhenPlusMultiPredicate(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertWhen(Match(anyOf: [P.a, P.b]), block, line: line)
    }

    func testWhenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                when(.coin) {
                    match(any: .a, .b) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
        }
    }

    func testWhenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                match(any: .a, .b) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
        }
    }

    func testWhenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                when(.coin) {
                    match(any: [.a, .b]) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
        }
    }

    func testWhenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                match(any: [.a, .b]) {
                    when(.coin) {
                        then(.alarming)
                        then()
                        then(.alarming) | e.fulfill
                        then()          | e.fulfill
                    }
                }
            }
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
        tr[0].actions[0]()
        tr[1].actions[0]()
    }

    func assertThen(
        _ m: Match = .none,
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .reset, .alarming, m, tr, line)
        assertContains(.locked, .pass, .alarming, m, tr, line)
        assertCount(2, tr, line: line)

        callActions(tr)
    }

    func testThenContext() {
        testWithExpectation(count: 2) { e in
            assertThen {
                then(.alarming) {
                    when(.reset) | e.fulfill
                    when(.pass)  | e.fulfill
                }
            }
        }
    }

    func assertThenPlusSinglePredicate(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertThen(Match(anyOf: [P.a]), block, line: line)
    }

    func testThenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusSinglePredicate {
                then(.alarming) {
                    match(.a) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func testThenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusSinglePredicate {
                match(.a) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func assertThenPlusMultiplePredicates(
        _ block: () -> [WTAPRow<State, Event>],
        line: UInt = #line
    ) {
        assertThen(Match(anyOf: [P.a, P.b]), block, line: line)
    }

    func testThenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                then(.alarming) {
                    match(any: .a, .b) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func testThenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                match(any: .a, .b) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func testThenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                then(.alarming) {
                    match(any: [.a, .b]) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func testThenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                match(any: [.a, .b]) {
                    then(.alarming) {
                        when(.reset) | e.fulfill
                        when(.pass)  | e.fulfill
                    }
                }
            }
        }
    }

    func testThenPlusSinglePredicateInsideAndOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                match(.a) {
                    then(.alarming) {
                        match(.b) {
                            when(.reset) | e.fulfill
                            when(.pass)  | e.fulfill
                        }
                    }
                }
            }
        }
    }
}

class PredicateTests: TestingBase {
    enum P: PredicateProtocol { case a, b }
    enum Q: PredicateProtocol { case a, b }
    enum R: PredicateProtocol { case a, b }
}

final class MatcherTests: PredicateTests {
    // first we need a list of all types not represented in either any or all
    // then we need the complete list of their permutations
    // for each of our existing anys, we need to create a new list of permutations:
    // for each permutation, add the single any, and all the alls
    // fsm.handleEvent has to throw if the predicate array count is unexpected
    // Match itself will have an isValid check that its alls and anys make sense
    
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
    
    func testAnyAndAllMatcherWithOther() {
        assertMatches(allOf: [P.a],
                      anyOf: [Q.a, Q.b],
                      adding: [[R.a],
                               [R.b]],
                      equals: [[P.a, Q.a, R.a],
                               [P.a, Q.a, R.b],
                               [P.a, Q.b, R.a],
                               [P.a, Q.b, R.b]])
    }
}

extension Collection where Element == P {
    var erased: [AnyPredicate] {
        map(\.erase)
    }
}

extension TableRow {
    subscript(index: Int) -> WTAP<S, E> {
        wtaps[index]
    }
    
    var firstActions: [() -> ()] {
        wtaps.first?.actions ?? []
    }
}

final class CharacterisationTests: PredicateTests {
    func testPermutations() {
        let predicates: [any PredicateProtocol] = [Q.a, Q.b, P.a, P.b, R.b]
        
        let expected = [[P.a, Q.a, R.a],
                        [P.b, Q.a, R.a],
                        [P.a, Q.a, R.b],
                        [P.b, Q.a, R.b],
                        [P.a, Q.b, R.a],
                        [P.b, Q.b, R.a],
                        [P.a, Q.b, R.b],
                        [P.b, Q.b, R.b]].erasedSets
        
        XCTAssertEqual(expected, predicates.uniquePermutationsOfAllCases)
    }
}

extension Collection where Element == [any PredicateProtocol] {
    var erasedSets: Set<Set<AnyPredicate>> {
        Set(map { Set($0.erased) })
    }
}

