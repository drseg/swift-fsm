import XCTest
@testable import SwiftFSM

enum P: PredicateProtocol { case a, b, c, d, e }

class ComplexTransitionBuilderTestBase: TestingBase, ComplexTransitionBuilder {
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
        XCTAssertEqual(c, tr.wtams.count, line: line)
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
            tr.wtams.contains(
                WTAM(events: w,
                     state: t,
                     actions: [],
                     match: m,
                     file: "",
                     line: -1)
            ),
            notFoundMessage(w, t, m, tr),
            line: line)
        
        assertGivenStates(tr.givenStates, contains: g, line: line)
    }
    
    func assertAllSatisfy(
        _ g: State,
        _ w: [Event],
        _ t: State,
        _ m: Match = .none,
        _ tr: TableRow<State, Event>,
        _ line: UInt = #line
    ) {
        XCTAssertTrue(
            tr.wtams.allSatisfy {
                $0 == WTAM(events: w,
                           state: t,
                           actions: [],
                           match: m,
                           file: "",
                           line: -1)
            },
            notFoundMessage(w, t, m, tr),
            line: line)
        
        assertGivenStates(tr.givenStates, contains: g, line: line)
    }
    
    func notFoundMessage(
        _ w: [Event],
        _ t: State,
        _ m: Match,
        _ tr: TR
    ) -> String {
        "\n(\(w), \(t), \(m)) \nnot found in: \n\(tr.description)"
    }
    
    func assertGivenStates(_ ss: [State], contains s: State, line: UInt) {
        XCTAssertTrue(ss.contains(s),
                      "\n'\(s)' not found in: \(ss)",
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
    
    func matchAny(_ ps: P...) -> Match {
        Match(anyOf: ps)
    }
}

final class TestMatchAsPrimaryBlock: ComplexTransitionBuilderTestBase {
    @WTAMBuilder<S, E> func wtaPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when(.pass, line: 10) | then(.unlocked) | e.fulfill
        when(.pass)           | then()          | e.fulfill
        when(.pass)           | then(.unlocked)
        when(.pass)           | then()
    }
    
    @WTAMBuilder<S, E> func varWTAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when(.pass, .coin, line: 10) | then(.unlocked) | e.fulfill
        when(.pass, .coin)           | then()          | e.fulfill
        when(.pass, .coin)           | then(.unlocked)
        when(.pass, .coin)           | then()
    }
    
    @WTAMBuilder<S, E> func arrayWTAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when([.pass, .coin], line: 10) | then(.unlocked) | e.fulfill
        when([.pass, .coin])           | then()          | e.fulfill
        when([.pass, .coin])           | then(.unlocked)
        when([.pass, .coin])           | then()
    }
    
    func assertMatchPlusWTAs(
        _ m: Match,
        _ wtamRows: (XCTestExpectation) -> [WTAMRow<S, E>],
        _ line: UInt = #line,
        _ block: (() -> ([WTAMRow<S, E>])) -> [WTAMRow<S, E>]
    ) {
        testWithExpectation(count: 2, line: line) { e in
            let wtamRows = wtamRows(e)
            assertMatchPlusWTAs(m, wtamRows, line) {
                define(.unlocked) {
                    block { wtamRows }
                }
            }
        }
    }
    
    func assertMatchPlusWTAs(
        _ m: Match,
        _ wtamRows: [WTAMRow<S, E>],
        _ line: UInt = #line,
        _ block: () -> TableRow<State, Event>
    ) {
        let tr = block()

        let actions = tr.wtams.map(\.actions)
        let expectedEvents = wtamRows
            .map(\.wtam)
            .compactMap { $0 }
            .map(\.events)
            .first ?? []
        
        actions.prefix(2).flatten.executeAll()
        XCTAssertTrue(actions.suffix(2).flatten.isEmpty)
        
        assertFileAndLine(10, forEvents: expectedEvents, in: tr, errorLine: line)
        assertAllSatisfy(.unlocked, expectedEvents, .unlocked, m, tr, line)
        assertCount(4, tr, line: line)
    }
    
    func testEmptyMatchBlock() {
        assertEmptyBlock { (match(.a) { }) as [WTAMRow<S, E>] }
        assertEmptyBlock { (match(anyOf: .a) { }) as [WTAMRow<S, E>] }
        assertEmptyBlock { (match(anyOf: [.a]) { }) as [WTAMRow<S, E>] }
        
        assertEmptyBlock { (match(.a) { }) as [WAMRow<E>] }
        assertEmptyBlock { (match(anyOf: .a) { }) as [WAMRow<E>] }
        assertEmptyBlock { (match(anyOf: [.a]) { }) as [WAMRow<E>] }
        
        assertEmptyBlock { (match(.a) { }) as [TAMRow<S>] }
        assertEmptyBlock { (match(anyOf: .a) { }) as [TAMRow<S>] }
        assertEmptyBlock { (match(anyOf: [.a]) { }) as [TAMRow<S>] }
    }
    #warning("also need to test empty sub blocks")
    
    func assertSingleMatchAnyPlusWTAs(
        line: UInt = #line,
        _ expected: (XCTestExpectation) -> [WTAMRow<S, E>]
    ) {
        assertMatchPlusWTAs(matchAny(.a), expected, line) { rows in
            match(.a) { rows() }
        }
    }
    
    func assertVarargMatchAnyPlusWTAs(
        line: UInt = #line,
        _ expected: (XCTestExpectation) -> [WTAMRow<S, E>]
    ) {
        assertMatchPlusWTAs(matchAny(.a, .b), expected, line) { rows in
            match(anyOf: .a, .b) { rows() }
        }
    }
    
    func assertArrayMatchAnyPlusWTAs(
        line: UInt = #line,
        _ expected: (XCTestExpectation) -> [WTAMRow<S, E>]
    ) {
        assertMatchPlusWTAs(matchAny(.a, .b), expected, line) { rows in
            match(anyOf: [.a, .b]) { rows() }
        }
    }
    
    func testMatchBlockWithWhenThenAction() {
        assertSingleMatchAnyPlusWTAs(wtaPermutations)
        assertSingleMatchAnyPlusWTAs(varWTAPermutations)
        assertSingleMatchAnyPlusWTAs(arrayWTAPermutations)
        
        assertVarargMatchAnyPlusWTAs(wtaPermutations)
        assertVarargMatchAnyPlusWTAs(varWTAPermutations)
        assertVarargMatchAnyPlusWTAs(arrayWTAPermutations)
        
        assertArrayMatchAnyPlusWTAs(wtaPermutations)
        assertArrayMatchAnyPlusWTAs(varWTAPermutations)
        assertArrayMatchAnyPlusWTAs(arrayWTAPermutations)
    }
    
    @WTAMBuilder<S, E> func whenBlockTAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when(.pass, line: 10) {
            then(.unlocked) | e.fulfill
            then()          | e.fulfill
            then(.unlocked)
            then()
        }
    }
    
    @WTAMBuilder<S, E> func whenVarargBlockTAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when(.pass, .coin, line: 10) {
            then(.unlocked) | e.fulfill
            then()          | e.fulfill
            then(.unlocked)
            then()
        }
    }
    
    @WTAMBuilder<S, E> func whenArrayBlockTAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        when([.pass, .coin], line: 10) {
            then(.unlocked) | e.fulfill
            then()          | e.fulfill
            then(.unlocked)
            then()
        }
    }
    
    func testMatchBlockPlusWhenBlockPlusThenAction() {
        assertSingleMatchAnyPlusWTAs(whenBlockTAPermutations)
        assertSingleMatchAnyPlusWTAs(whenVarargBlockTAPermutations)
        assertSingleMatchAnyPlusWTAs(whenArrayBlockTAPermutations)
        
        assertVarargMatchAnyPlusWTAs(whenBlockTAPermutations)
        assertVarargMatchAnyPlusWTAs(whenVarargBlockTAPermutations)
        assertVarargMatchAnyPlusWTAs(whenArrayBlockTAPermutations)
        
        assertArrayMatchAnyPlusWTAs(whenBlockTAPermutations)
        assertArrayMatchAnyPlusWTAs(whenVarargBlockTAPermutations)
        assertArrayMatchAnyPlusWTAs(whenArrayBlockTAPermutations)
    }
    
    @WTAMBuilder<S, E> func thenBlockWAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        then(.unlocked) {
            when(.pass, line: 10) | e.fulfill
            when(.pass)           | e.fulfill
        }
        
        then() {
            when(.pass)
            when(.pass)
        }
    }
    
    @WTAMBuilder<S, E> func thenBlockVarargWAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        then(.unlocked) {
            when(.pass, .coin, line: 10) | e.fulfill
            when(.pass, .coin)           | e.fulfill
        }
        
        then() {
            when(.pass, .coin)
            when(.pass, .coin)
        }
    }
    
    @WTAMBuilder<S, E> func thenBlockArrayWAPermutations(
        _ e: XCTestExpectation
    ) -> [WTAMRow<S, E>] {
        then(.unlocked) {
            when([.pass, .coin], line: 10) | e.fulfill
            when([.pass, .coin])           | e.fulfill
        }
        
        then() {
            when([.pass, .coin])
            when([.pass, .coin])
        }
    }
    
    func testMatchBlockPlusThenBlockPlusWhenAction() {
        assertSingleMatchAnyPlusWTAs(thenBlockWAPermutations)
        assertSingleMatchAnyPlusWTAs(thenBlockVarargWAPermutations)
        assertSingleMatchAnyPlusWTAs(thenBlockArrayWAPermutations)
        
        assertVarargMatchAnyPlusWTAs(thenBlockWAPermutations)
        assertVarargMatchAnyPlusWTAs(thenBlockVarargWAPermutations)
        assertVarargMatchAnyPlusWTAs(thenBlockArrayWAPermutations)
        
        assertArrayMatchAnyPlusWTAs(thenBlockWAPermutations)
        assertArrayMatchAnyPlusWTAs(thenBlockVarargWAPermutations)
        assertArrayMatchAnyPlusWTAs(thenBlockArrayWAPermutations)
    }
}

final class ComplexTransitionBuilderTests: ComplexTransitionBuilderTestBase {
    // MARK: Original tests
    
    func testMatchWithNestedEmptyBlocks() {
        assertEmptyBlocks(atLineOffsets: [3, 4, 5, 7, 9, 10, 11, 13]) {
            define(.unlocked) {
                match(.a) {
                    when(.coin) { }
                    when(.coin, .pass) { }
                    when([.coin, .pass]) { }
                    
                    then(.unlocked) { }
                    
                    action({ }) { }
                    actions({ }, { }) { }
                    actions([{ }, { }]) { }
                    
                    match(.b) { }
                }
            }
        }
    }
    
    func testMatcherContext() {
        testWithExpectation { e in
            let tr =
            define(.locked) {
                match(.a) {
                    match(anyOf: .b, .c) {
                        match(anyOf: [.d, .e]) {
                            when(.coin, line: 10) | then() | e.fulfill
                        }
                    }
                }
            }
                        
            let m = matchAny(.a, .b, .c, .d, .e)
            assertContains(.locked, .coin, .locked, m, tr: tr)
            assertFileAndLine(10, forEvent: .coin, in: tr)
            tr[0].actions[0]()
        }
    }
    
    func tableRow(_ block: () -> [WTAMRow<State, Event>]) -> TR {
        define(.locked) { block() }
    }

    func assertWithAction(
        _ m: Match,
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .coin, .unlocked, m, tr, line)
        assertContains(.locked, .pass, .locked, m, tr, line)
        assertCount(2, tr, line: line)

        assertFileAndLine(10, forEvent: .coin, in: tr, errorLine: line)

        tr.wtams.map(\.actions).flatten.executeAll()
    }

    func assertSinglePredicateWithAction(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertWithAction(matchAny(P.a), block, line: line)
    }
    
    @WTAMBuilder<S, E> var coinUnlockedPassLocked: [WTAMRow<S, E>] {
        when(.coin, line: 10) | then(.unlocked)
        when(.pass)           | then()
    }

    func testSinglePredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertSinglePredicateWithAction {
                match(.a) {
                    action(e.fulfill) {
                        coinUnlockedPassLocked
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
                        coinUnlockedPassLocked
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
                        coinUnlockedPassLocked
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
                        coinUnlockedPassLocked
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
                        coinUnlockedPassLocked
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
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func assertMultiPredicateWithAction(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertWithAction(matchAny(.a, .b), block, line: line)
    }

    func testMultiPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                match(anyOf: .a, .b) {
                    action(e.fulfill) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                action(e.fulfill) {
                    match(anyOf: .a, .b) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(anyOf: .a, .b) {
                    actions(e.fulfill, e.fulfill) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testMultiPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill, e.fulfill) {
                    match(anyOf: .a, .b) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testMultiPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(anyOf: .a, .b) {
                    actions([e.fulfill, e.fulfill]) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testMultiPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions([e.fulfill, e.fulfill]) {
                    match(anyOf: .a, .b) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionInside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                match(anyOf: [.a, .b]) {
                    actions(e.fulfill) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionOutside() {
        testWithExpectation(count: 2) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill) {
                    match(anyOf: [.a, .b]) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(anyOf: [.a, .b]) {
                    actions(e.fulfill, e.fulfill) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions(e.fulfill, e.fulfill) {
                    match(anyOf: [.a, .b]) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithArrayActionsInside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                match(anyOf: [.a, .b]) {
                    actions([e.fulfill, e.fulfill]) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }

    func testArrayPredicateWithArrayActionsOutside() {
        testWithExpectation(count: 4) { e in
            assertMultiPredicateWithAction {
                actions([e.fulfill, e.fulfill]) {
                    match(anyOf: [.a, .b]) {
                        coinUnlockedPassLocked
                    }
                }
            }
        }
    }
    
    func testActionsWithEmptyMatch() {
        assertEmptyBlocks(atLineOffsets: [3, 7, 11]) {
            define(.unlocked) {
                action({ }) {
                    match(.a) { }
                }
                
                actions({ }, { }) {
                    match(.a) { }
                }
                
                actions([{ }, { }]) {
                    match(.a) { }
                }
            }
        }
    }

    func testThenWithNoArgument() {
        let t1: Then = then()
        let t2: TAMRow = then()

        XCTAssertNil(t1.state)
        XCTAssertNil(t2.tam?.state)

        XCTAssertTrue(t2.tam?.actions.isEmpty ?? false)
        XCTAssertTrue(t2.tam?.match.allOf.isEmpty ?? false)
    }
    
    func testWhenDefaultFileAndLine() {
        let l1 = #line; let w1 = when(.coin)
        let l2 = #line; let w2 = when([.coin])
        let l3 = #line; let w3 = when(.coin)   { then() }
        let l4 = #line; let w4 = when([.coin]) { then() }
        
        XCTAssertEqual(w1.wam?.file, #file)
        XCTAssertEqual(w2.wam?.file, #file)
        
        XCTAssertEqual(w3[0].wtam?.file, #file)
        XCTAssertEqual(w4[0].wtam?.file, #file)
        
        XCTAssertEqual(w1.wam?.line, l1)
        XCTAssertEqual(w2.wam?.line, l2)
        
        XCTAssertEqual(w3[0].wtam?.line, l3)
        XCTAssertEqual(w4[0].wtam?.line, l4)
    }
    
    func testEmptyWhenBlock() {
        assertEmptyBlock { when(.coin) { } }
        assertEmptyBlock { when([.coin]) { } }
    }
    
    func testWhenWithNestedEmptyBlocks() {
        assertEmptyBlocks(atLineOffsets: [3]) {
            define(.locked) {
                when(.pass) {
                    match(.a) {} // should this be allowed?
                    
                    // disallowed:
                    // then(.unlocked) {}
                    // action({}) {}
                }
            }
        }
    }
    
    func testSingleWhenContext() {
        testWithExpectation(count: 2) { e in
            let tr =
            define(.locked) {
                when(.coin, line: 10) {
                    then(.unlocked)
                    then()
                    then(.alarming) | e.fulfill
                    then()          | e.fulfill
                }
            }

            assertContains(.locked, .coin, .unlocked, tr)
            assertContains(.locked, .coin, .locked, tr)
            assertContains(.locked, .coin, .alarming, tr)
            
            assertFileAndLine(10, forEvent: .coin, in: tr)
        
            assertCount(4, tr)

            tr[0].actions.first?()
            tr[1].actions.first?()
            tr[2].actions[0]()
            tr[3].actions[0]()
        }
    }

    func assertMultiWhenContext(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, [.coin, .pass], .alarming, tr, line)
        assertCount(4, tr, line: line)
        
        assertFileAndLine(10, forEvents: [.coin, .pass], in: tr, errorLine: line)
        
        tr[0].actions.first?()
        tr[1].actions.first?()

        tr[2].actions[0]()
        tr[3].actions[0]()
    }
    
    @TAMBuilder<S> func allThenOverloads(_ e: XCTestExpectation) -> [TAMRow<S>] {
        then(.alarming)
        then()
        then(.alarming) | e.fulfill
        then()          | e.fulfill
    }
    
    func testEmptyThenBlock() {
        assertEmptyBlock { then(.unlocked) { } }
    }

    func testMultiWhenContext() {
        testWithExpectation(count: 2) { e in
            assertMultiWhenContext {
                when(.coin, .pass, line: 10) {
                    allThenOverloads(e)
                }
            }
        }
    }

    func testArrayWhenContext() {
        testWithExpectation(count: 2) { e in
            assertMultiWhenContext {
                when([.coin, .pass], line: 10) {
                    allThenOverloads(e)
                }
            }
        }
    }

    func assertWhen(
        _ m: Match = .none,
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .coin, .alarming, m, tr, line)
        assertCount(4, tr, line: line)
        assertFileAndLine(10, forEvent: .coin, in: tr, errorLine: line)

        tr[0].actions.first?()
        tr[1].actions.first?()
        tr[2].actions[0]()
        tr[3].actions[0]()
    }

    func assertWhenPlusSinglePredicate(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertWhen(matchAny(P.a), block, line: line)
    }

    func testWhenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusSinglePredicate {
                when(.coin, line: 10) {
                    match(.a) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func testWhenPlusSinglePredicateOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusSinglePredicate {
                match(.a) {
                    when(.coin, line: 10) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func assertWhenPlusMultiPredicate(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertWhen(Match(anyOf: [P.a, P.b]), block, line: line)
    }

    func testWhenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                when(.coin, line: 10) {
                    match(anyOf: .a, .b) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func testWhenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                match(anyOf: .a, .b) {
                    when(.coin, line: 10) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func testWhenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                when(.coin, line: 10) {
                    match(anyOf: [.a, .b]) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func testWhenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertWhenPlusMultiPredicate {
                match(anyOf: [.a, .b]) {
                    when(.coin, line: 10) {
                        allThenOverloads(e)
                    }
                }
            }
        }
    }

    func testWhenActionCombinations() {
        let l1 = #line; let wam1 = when(.reset)          | { }
        let l2 = #line; let wam2 = when(.reset, .pass)   | { }
        let l3 = #line; let wam3 = when([.reset, .pass]) | [{ }]

        let l4 = #line; let wam4 = when(.reset)
        let l5 = #line; let wam5 = when(.reset, .pass)
        let l6 = #line; let wam6 = when([.reset, .pass])

        let all = [wam1, wam2, wam3, wam4, wam5, wam6]
        let allLines = [l1, l2, l3, l4, l5, l6]

        all.prefix(3).forEach {
            XCTAssertEqual($0.wam?.actions.count, 1)
        }

        all.suffix(3).forEach {
            XCTAssertEqual($0.wam?.actions.count, 0)
        }

        zip(all, allLines).forEach {
            XCTAssertEqual($0.0.wam?.file, #file)
            XCTAssertEqual($0.0.wam?.line, $0.1)
        }

        [wam1, wam4].map(\.wam).map(\.?.events).forEach {
            XCTAssertEqual($0, [.reset])
        }

        [wam2, wam3, wam5, wam6].map(\.wam).map(\.?.events).forEach {
            XCTAssertEqual($0, [.reset, .pass])
        }
    }

    func callActions(_ tr: TR) {
        tr[0].actions[0]()
        tr[1].actions[0]()
    }

    func assertThen(
        _ m: Match = .none,
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        let tr = tableRow(block)

        assertContains(.locked, .reset, .alarming, m, tr, line)
        assertContains(.locked, .pass, .alarming, m, tr, line)
        assertCount(2, tr, line: line)
        assertFileAndLine(10, forEvent: .reset, in: tr, errorLine: line)

        callActions(tr)
    }

    @WAMBuilder<E> func resetFulfillPassFulfill(_ e: XCTestExpectation) -> [WAMRow<E>] {
        when(.reset, line: 10) | e.fulfill
        when(.pass)            | e.fulfill
    }
    
    func testThenContext() {
        testWithExpectation(count: 2) { e in
            assertThen {
                then(.alarming) {
                    resetFulfillPassFulfill(e)
                }
            }
        }
    }

    func assertThenPlusSinglePredicate(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertThen(matchAny(P.a), block, line: line)
    }
    

    func testThenPlusSinglePredicateInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusSinglePredicate {
                then(.alarming) {
                    match(.a) {
                        resetFulfillPassFulfill(e)
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
                        resetFulfillPassFulfill(e)
                    }
                }
            }
        }
    }

    func assertThenPlusMultiplePredicates(
        _ block: () -> [WTAMRow<State, Event>],
        line: UInt = #line
    ) {
        assertThen(matchAny(P.a, P.b), block, line: line)
    }

    func testThenPlusMultiplePredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                then(.alarming) {
                    match(anyOf: .a, .b) {
                        resetFulfillPassFulfill(e)
                    }
                }
            }
        }
    }

    func testThenPlusMultiplePredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                match(anyOf: .a, .b) {
                    then(.alarming) {
                        resetFulfillPassFulfill(e)
                    }
                }
            }
        }
    }

    func testThenPlusArrayPredicatesInside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                then(.alarming) {
                    match(anyOf: [.a, .b]) {
                        resetFulfillPassFulfill(e)
                    }
                }
            }
        }
    }

    func testThenPlusArrayPredicatesOutside() {
        testWithExpectation(count: 2) { e in
            assertThenPlusMultiplePredicates {
                match(anyOf: [.a, .b]) {
                    then(.alarming) {
                        resetFulfillPassFulfill(e)
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
                            resetFulfillPassFulfill(e)
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
        XCTAssertEqual(match.allMatches(a.map { $0.erase() }.asSets),
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

extension TableRow {
    subscript(index: Int) -> WTAM<S, E> {
        wtams[index]
    }
    
    var firstActions: [() -> ()] {
        wtams.first?.actions ?? []
    }
}

final class CharacterisationTests: PredicateTests {
    func testPermutations() {
        let predicates: [any PredicateProtocol] = [Q.a, Q.b, P.a, P.b, R.b, R.b]
        
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
        Set(map { Set($0.erase()) })
    }
}

