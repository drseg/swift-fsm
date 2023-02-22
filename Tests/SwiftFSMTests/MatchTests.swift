//
//  MatchTests.swift
//
//  Created by Daniel Segall on 22/02/2023.
//

import XCTest
@testable import SwiftFSM

final class MatchTests: XCTestCase {
    enum P: PredicateProtocol { case a, b }
    enum Q: PredicateProtocol { case a, b }
    enum R: PredicateProtocol { case a, b }
    
    func assertMatches(
        anyOf: [any PredicateProtocol] = [],
        allOf: [any PredicateProtocol] = [],
        adding a: [[any PredicateProtocol]] = [],
        equals expected: [[any PredicateProtocol]],
        line: UInt = #line
    ) {
        let match = Match(any: anyOf, all: allOf)
        XCTAssertEqual(match.allMatches(a.map { $0.erase() }.asSets),
                       expected.erasedSets,
                       line: line)
    }
    
    func testHashable() {
        1000 * {
            let dict = [Match(): Match()]
            XCTAssertEqual(Match(), dict[Match()])
        }
    }
    
    func testAddingEmptyMatches() {
        XCTAssertEqual(Match() + Match(), Match())
    }
    
    func testAddingAnyToEmpty() {
        XCTAssertEqual(Match() + Match(any: [P.a]), Match(any: [P.a]))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(Match() + Match(all: [P.a]), Match(all: [P.a]))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = Match(any: [P.a], all: [P.b])
        XCTAssertEqual(Match() + addend, addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = Match(any: [P.a])
        let m2 = Match(any: [Q.a])
        
        XCTAssertEqual(m1 + m2, Match(any: [P.a, Q.a]))
    }
    
    func testAddingAlltoAny() {
        let m1 = Match(any: [Q.a])
        let m2 = Match(all: [P.a])
        
        XCTAssertEqual(m1 + m2, Match(any: [Q.a], all: [P.a]))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = Match(any: [Q.a])
        let m2 = Match(any: [R.a], all: [P.a])
        
        XCTAssertEqual(m1 + m2, Match(any: [Q.a, R.a], all: [P.a]))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = Match(any: [P.a], all: [Q.a])
        let m2 = Match(any: [P.b], all: [Q.b])
        
        XCTAssertEqual(m1 + m2, Match(any: [P.a, P.b], all: [Q.a, Q.b]))
    }

    func testMatchFinalisesToItself() {
        XCTAssertEqual(Match(any: [P.a]),
                       try? Match(any: [P.a]).finalise().get())
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        let match = Match().prepend(Match(any: [P.a]))

        XCTAssertEqual(Match(any: [P.a]),
                       try? match.finalise().get())
    }
    
    func testMatchWithNextFinalisesToSum() {
        let match = Match(any: [P.a],
                          all: [P.b]).prepend(Match(any: [Q.a],
                                                    all: [Q.b]))

        XCTAssertEqual(Match(any: [P.a, Q.a], all: [P.b, Q.b]),
                       try? match.finalise().get())
    }
    
    func assertDuplicateTypes(_ m: Match, line: UInt = #line) {
        assertThrows(m, line: line) {
            XCTAssertEqual($0 as? MatchError,
                           .duplicateTypes(message: "P.a, P.b",
                                           file: m.file,
                                           line: m.line),
                           line: line)
        }
    }
    
    func assertThrows(
        _ m: Match,
        line: UInt = #line,
        _ assertion: (Error) -> ()
    ) {
        XCTAssertThrowsError(try m.finalise().get(), line: line) {
            assertion($0)
        }
    }
    
    func testMatchWithMultipleInstancesOfSameTypeInAllIsError() {
        assertDuplicateTypes(Match(all: [P.a, P.b]))
    }
    
    func testMatchFormingDuplicateTypesOnFinaliseIsError() {
        assertDuplicateTypes(Match(all: [P.a]).prepend(Match(all: [P.b])))
    }
    
    func assertDuplicateValues(_ m: Match, line: UInt = #line) {
        assertThrows(m) {
            XCTAssertEqual($0 as? MatchError,
                           .duplicateValues(message: "P.a",
                                            file: m.file,
                                            line: m.line),
                           line: line)
        }
    }
    
    func testMatchWithSamePredicateInAnyAndAllIsError() {
        assertDuplicateValues(Match(any: [P.a, P.b], all: [P.a]))
    }
    
    func testMatchFormingDuplicateValuesOnFinaliseIsError() {
        assertDuplicateValues(
            Match(any: [P.b], all: [P.a]).prepend(Match(any: [P.a]))
        )
    }
    
    func testIsErrorWhenNextMatchIsError() {
        assertDuplicateTypes(Match(all: [P.a, P.b]).prepend(Match()))
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
        assertMatches(anyOf: [R.a, R.b],
                      allOf: [P.a, Q.a],
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
        assertMatches(anyOf: [Q.a, Q.b],
                      allOf: [P.a],
                      adding: [[R.a],
                               [R.b]],
                      equals: [[P.a, Q.a, R.a],
                               [P.a, Q.a, R.b],
                               [P.a, Q.b, R.a],
                               [P.a, Q.b, R.b]])
    }
}

extension Collection where Element == [any PredicateProtocol] {
    var erasedSets: Set<Set<AnyPredicate>> {
        Set(map { Set($0.erase()) })
    }
}

infix operator *

func * (lhs: Int, rhs: Action) {
    for _ in 1...lhs {
        rhs()
    }
}
