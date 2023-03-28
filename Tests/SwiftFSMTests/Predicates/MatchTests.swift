//
//  MatchTests.swift
//
//  Created by Daniel Segall on 22/02/2023.
//

import XCTest
@testable import SwiftFSM

enum P: Predicate { case a, b, c }
enum Q: Predicate { case a, b    }
enum R: Predicate { case a, b    }
enum S: Predicate { case a, b    }
enum T: Predicate { case a, b    }
enum U: Predicate { case a, b    }
enum V: Predicate { case a, b    }
enum W: Predicate { case a, b    }

class MatchTests: XCTestCase {
    let p1 = P.a, p2 = P.b, p3 = P.c
    let q1 = Q.a, q2 = Q.b
    let r1 = R.a, r2 = R.b
    let s1 = S.a, s2 = S.b
    let t1 = T.a, t2 = T.b
    let u1 = U.a, u2 = U.b
}

class BasicTests: MatchTests {
    func testEquatable() {
        XCTAssertEqual(Match(), Match())
        
        XCTAssertEqual(Match(any: p1, p2, all: q1, r1),
                       Match(any: p1, p2, all: q1, r1))
        
        XCTAssertEqual(Match(any: p1, p2, all: q1, r1),
                       Match(any: p2, p1, all: r1, q1))
        
        XCTAssertNotEqual(Match(any: p1, p2, all: q1, r1),
                          Match(any: p1, s2, all: q1, r1))
        
        XCTAssertNotEqual(Match(any: p1, p2, all: q1, r1),
                          Match(any: p1, p2, all: q1, s1))
        
        XCTAssertNotEqual(Match(any: p1, p2, p2, all: q1, r1),
                          Match(any: p1, p2, all: q1, r1))
        
        XCTAssertNotEqual(Match(any: p1, p2, all: q1, r1, r1),
                          Match(any: p1, p2, all: q1, r1))
    }
}

class AdditionTests: MatchTests {
    func testAdditionTakesFileAndLineFromLHS() {
        let m1 = Match(file: "1", line: 1)
        let m2 = Match(file: "2", line: 2)
        
        XCTAssertEqual((m1 + m2).file, "1")
        XCTAssertEqual((m2 + m1).file, "2")
        
        XCTAssertEqual((m1 + m2).line, 1)
        XCTAssertEqual((m2 + m1).line, 2)
    }
    
    func testAddingEmptyMatches() {
        XCTAssertEqual(Match() + Match(), Match())
    }
    
    func testAddingAnyToEmpty() {
        XCTAssertEqual(Match() + Match(any: p1, p2),
                       Match(any: p1, p2))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(Match() + Match(all: p1), Match(all: p1))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = Match(any: p1, p2, all: q1, q2)
        XCTAssertEqual(Match() + addend, addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = Match(any: p1, p2)
        let m2 = Match(any: q1, q2)
        
        XCTAssertEqual(m1 + m2, Match(any: [[p1, p2], [q1, q2]]))
    }
    
    func testAddingAlltoAny() {
        let m1 = Match(any: q1, q2)
        let m2 = Match(all: p1, p2)
        
        XCTAssertEqual(m1 + m2, Match(any: q1, q2,
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = Match(any: q1, q2)
        let m2 = Match(any: r1, r2, all: p1, p2)
        
        XCTAssertEqual(m1 + m2, Match(any: [[q1, q2], [r1, r2]],
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = Match(any: p1, p2, all: q1, q2)
        let m2 = Match(any: r1, r2, all: s1, s2)
        
        XCTAssertEqual(m1 + m2, Match(any: [[p1, p2], [r1, r2]],
                                      all: q1, q2, s1, s2))
    }
}

class FinalisationTests: MatchTests {
    func assertFinalise(_ m: Match, _ e: Match, line: UInt = #line) {
        XCTAssertEqual(e, try! m.finalised().get(), line: line)
    }

    func testMatchFinalisesToItself() {
        assertFinalise(Match(all: p1),
                       Match(all: p1))
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        assertFinalise(Match().prepend(Match(any: p1, p2)),
                       Match(any: p1, p2))
    }
    
    func testMatchWithNextFinalisesToSum() {
        assertFinalise(Match(any: p1, p2,
                             all: q1, r1).prepend(Match(any: s1, s2,
                                                        all: t1, u1)),
                       Match(any: [[p1, p2], [s1, s2]],
                             all: q1, r1, t1, u1))
    }
    
    func testLongChain() {
        var match = Match(all: p1)
        100 * { match = match.prepend(Match()) }
        XCTAssertEqual(Match(all: p1), try! match.finalised().get())
    }
}

class ValidationTests: MatchTests {
    func assert(match m: Match, is e: MatchError, line: UInt = #line) {
        XCTAssertThrowsError(try m.finalised().get(), line: line) {
            XCTAssertEqual(String(describing: type(of: $0)),
                           String(describing: type(of: e)),
                           line: line)
            XCTAssertEqual($0 as? MatchError, e, line: line)
        }
    }
    
    func assertHasDuplicateTypes(_ m1: Match, line: UInt = #line) {
        let error = DuplicateMatchTypes(message: "p1, p2",
                                   files: [m1.file],
                                   lines: [m1.line])
        assert(match: m1, is: error, line: line)
    }
    
    func testEmptyMatch() {
        XCTAssertEqual(Match().finalised(), .success(Match()))
    }
    
    func testAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(Match(all: p1, p2))
    }
    
    func testAll_AddingAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(Match().prepend(Match(all: p1, p2)))
        assertHasDuplicateTypes(Match(all: p1, p2).prepend(Match()))
    }
    
    func assertDuplicateTypesWhenAdded(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let error = DuplicateMatchTypes(message: "p1, p2",
                                        files: [m1.file, m2.file],
                                        lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAllInvalid_AddingAllInvalid() {
        assertDuplicateTypesWhenAdded(Match(all: p1, p2),
                                      Match(all: p1, p2))
    }
    
    func testAll_AddingAll_FormingDuplicateTypes() {
        assertDuplicateTypesWhenAdded(Match(all: p1, q1),
                                      Match(all: p1, q1))
    }
    
    func assertHasDuplicateValues(_ m: Match, line: UInt = #line) {
        let error =  DuplicateMatchValues(message: "p1",
                                          files: [m.file],
                                          lines: [m.line])
        
        assert(match: m, is: error, line: line)
    }
    
    func testAny_All_WithSamePredicates() {
        assertHasDuplicateValues(Match(any: p1, p2, all: p1, q1))
    }
    
    func assertDuplicateValuesWhenAdded(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let error =  DuplicateMatchValues(message: "p1, p2",
                                          files: [m1.file, m2.file],
                                          lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAny_AddingAll_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(Match(any: p1, p2),
                                       Match(all: p1, q1))
    }
    
    func testAny_AddingAny_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(Match(any: p1, p2),
                                       Match(any: p1, p2))
    }
    
    func testAnyAndAny_FormingDuplicateTypes() {
        let match = Match(any: [[p1], [p2], [p3]])

        assert(match: match, is: DuplicateMatchTypes(message: "p1, p2, p3",
                                                     files: [match.file],
                                                     lines: [match.line]))
    }
}

class MatchCombinationsTests: MatchTests {
    func testAllEmpty() {
        XCTAssertEqual(Match().allPredicateCombinations([]), [])
    }
    
    func assertCombinations(
        anyOf: [any Predicate] = [],
        allOf: [any Predicate] = [],
        with a: [[any Predicate]] = [],
        expected: [[any Predicate]],
        eachRank: Int,
        line: UInt = #line
    ) {
        assertCombinations(anyOf: [anyOf],
                           allOf: allOf,
                           with: a,
                           expected: expected,
                           eachRank: eachRank,
                           line: line)
    }
    
    func assertCombinations(
        anyOf: [[any Predicate]],
        allOf: [any Predicate] = [],
        with a: [[any Predicate]] = [],
        expected: [[any Predicate]],
        eachRank: Int,
        line: UInt = #line
    ) {
        let match = Match(any: anyOf.map { $0.erased() }, all: allOf.erased())
        let additions = a.map { $0.erased() }.asSets
        
        let allCombinations = match.allPredicateCombinations(additions)
        let allRanks = allCombinations.map(\.rank)
        let allPredicates = Set(allCombinations.map(\.predicates))
        
        XCTAssertEqual(allPredicates, expected.erasedSets, line: line)
        XCTAssertTrue(allRanks.allSatisfy { $0 == eachRank }, "\(allRanks)", line: line)
    }
    
    func testEmptyMatcher() {
        assertCombinations(expected: [], eachRank: 0)
    }
    
    func testAnyOfSinglePredicate() {
        assertCombinations(anyOf: [P.a], expected: [[P.a]], eachRank: 1)
    }
    
    func testAnyOfMultiPredicate() {
        assertCombinations(anyOf: [P.a, P.b], expected: [[P.a], [P.b]], eachRank: 1)
    }
    
    func testAllOfSingleType() {
        assertCombinations(allOf: [P.a], expected: [[P.a]], eachRank: 1)
    }
    
    func testAllOfMultiTypeM() {
        assertCombinations(allOf: [P.a, Q.a], expected: [[P.a, Q.a]], eachRank: 2)
    }
    
    func testCombinedAnyAndAll() {
        assertCombinations(anyOf: [R.a, R.b],
                           allOf: [P.a, Q.a],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b]],
                           eachRank: 3)
    }
    
    func testEmptyMatcherWithSingleOther() {
        assertCombinations(with: [[P.a]],
                           expected: [[P.a]],
                           eachRank: 0)
    }
    
    func testEmptyMatcherWithMultiOther() {
        assertCombinations(with: [[P.a, Q.a]],
                           expected: [[P.a, Q.a]],
                           eachRank: 0)
    }
    
    func testEmptyMatcherWithMultiMultiOther() {
        assertCombinations(with: [[P.a, Q.a],
                                  [P.a, Q.b]],
                           expected: [[P.a, Q.a],
                                      [P.a, Q.b]],
                           eachRank: 0)
    }
    
    func testAnyMatcherWithOther() {
        assertCombinations(anyOf: [P.a, P.b],
                           with: [[Q.a, R.a],
                                  [Q.b, R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.b, R.b],
                                      [P.b, Q.a, R.a],
                                      [P.b, Q.b, R.b]],
                           eachRank: 1)
    }
    
    func testAllMatcherWithOther() {
        assertCombinations(allOf: [P.a, Q.a],
                           with: [[R.a],
                                  [R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b]],
                           eachRank: 2)
    }
    
    func testAnyAndAllMatcherWithOther() {
        assertCombinations(anyOf: [Q.a, Q.b],
                           allOf: [P.a],
                           with: [[R.a],
                                  [R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b],
                                      [P.a, Q.b, R.a],
                                      [P.a, Q.b, R.b]],
                           eachRank: 2)
    }
        
    func testAnyIgnoresTypesAlreadySpecified() {
        assertCombinations(anyOf: [P.a],
                           with: [[P.b, P.c, Q.a]],
                           expected: [[P.a, Q.a]],
                           eachRank: 1)
    }
    
    func testAllIgnoresTypesAlreadySpecified() {
        assertCombinations(allOf: [P.a],
                           with: [[P.b, P.c, Q.a]],
                           expected: [[P.a, Q.a]],
                           eachRank: 1)
    }
    
    func testAnyAllIgnoresTypesAlreadySpecified() {
        assertCombinations(anyOf: [P.a],
                           allOf: [R.a],
                           with: [[P.b, P.c, R.b, Q.a]],
                           expected: [[P.a, R.a, Q.a]],
                           eachRank: 2)
    }
    
    func testAllOfWithMultipleElements_OnePredicateEach() {
        assertCombinations(anyOf: [[P.a], [Q.a]],
                           expected: [[P.a, Q.a]],
                           eachRank: 2)
    }
    
    func testAllOfWithMultipleElements_TwoPredicatesEach() {
        assertCombinations(anyOf: [[P.a, P.b], [Q.a, Q.b]],
                           expected: [[P.a, Q.a], [P.b, Q.a], [P.a, Q.b], [P.b, Q.b]],
                           eachRank: 2)
    }
    
    func testAllOfWithMultipleElements_UnevenPredicates() {
        assertCombinations(anyOf: [[P.a, P.b], [Q.a]],
                           expected: [[P.a, Q.a], [P.b, Q.a]],
                           eachRank: 2)
    }
    
    func testAllOfWithMultipleElementsWithAnd() {
        assertCombinations(anyOf: [[P.a], [Q.a]],
                           allOf: [R.a, S.a],
                           expected: [[P.a, Q.a, R.a, S.a]],
                           eachRank: 4)
    }
    
    func testAllOfWithMultipleElementsWithAnd_TwoPredicatesEach() {
        assertCombinations(anyOf: [[P.a, P.b], [Q.a, Q.b]],
                           allOf: [R.a, S.a],
                           expected: [[P.a, Q.a, R.a, S.a],
                                      [P.b, Q.a, R.a, S.a],
                                      [P.a, Q.b, R.a, S.a],
                                      [P.b, Q.b, R.a, S.a]],
                           eachRank: 4)
    }
    
    func testAllOfWithMultipleElementsWithAnd_UnevenPredicates() {
        assertCombinations(anyOf: [[P.a, P.b], [Q.a]],
                           allOf: [R.a, S.a],
                           expected: [[P.a, Q.a, R.a, S.a],
                                      [P.b, Q.a, R.a, S.a]],
                           eachRank: 4)
    }
}

extension Match: CustomStringConvertible {
    public var description: String {
        "\(matchAny), \(matchAll)"
    }
}

extension MatchError: CustomStringConvertible {
    public var description: String {
        String.build {
            "Message: \(message)"
            "Files: \(files.map { URL(string: $0)!.lastPathComponent})"
            "Lines: \(lines)"
        }
    }
}

@resultBuilder struct StringBuilder: ResultBuilder { typealias T = String }
extension String {
    static func build(@StringBuilder _ b:  () -> [String]) -> String {
        b().joined(separator: "\n")
    }
}

extension MatchError: Equatable {
    public static func == (lhs: MatchError, rhs: MatchError) -> Bool {
        lhs.files.sorted() == rhs.files.sorted() &&
        lhs.lines.sorted() == rhs.lines.sorted()
    }
}

extension Collection where Element == [any Predicate] {
    var erasedSets: PredicateSets {
        Set(map { Set($0.erased()) })
    }
}

infix operator *

func * (lhs: Int, rhs: Action) {
    for _ in 1...lhs { rhs() }
}
