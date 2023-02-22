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
        let match = Match(anyOf: anyOf, allOf: allOf)
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
        XCTAssertEqual(Match() + Match(anyOf: [P.a]), Match(anyOf: [P.a]))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(Match() + Match(allOf: [P.a]), Match(allOf: [P.a]))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = Match(anyOf: [P.a], allOf: [P.b])
        XCTAssertEqual(Match() + addend, addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = Match(anyOf: [P.a])
        let m2 = Match(anyOf: [Q.a])
        
        XCTAssertEqual(m1 + m2, Match(anyOf: [P.a, Q.a]))
    }
    
    func testAddingAlltoAny() {
        let m1 = Match(anyOf: [Q.a])
        let m2 = Match(allOf: [P.a])
        
        XCTAssertEqual(m1 + m2, Match(anyOf: [Q.a], allOf: [P.a]))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = Match(anyOf: [Q.a])
        let m2 = Match(anyOf: [R.a], allOf: [P.a])
        
        XCTAssertEqual(m1 + m2, Match(anyOf: [Q.a, R.a], allOf: [P.a]))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = Match(anyOf: [P.a], allOf: [Q.a])
        let m2 = Match(anyOf: [P.b], allOf: [Q.b])
        
        XCTAssertEqual(m1 + m2, Match(anyOf: [P.a, P.b], allOf: [Q.a, Q.b]))
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
