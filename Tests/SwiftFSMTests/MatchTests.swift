//
//  MatchTests.swift
//
//  Created by Daniel Segall on 22/02/2023.
//

import XCTest
@testable import SwiftFSM

class MatchTests: XCTestCase {
    enum P: PredicateProtocol { case a, b, c }
    enum Q: PredicateProtocol { case a, b, c }
    enum R: PredicateProtocol { case a, b, c }
    enum S: PredicateProtocol { case a, b, c }
    enum T: PredicateProtocol { case a, b, c }
    enum U: PredicateProtocol { case a, b, c }
    enum V: PredicateProtocol { case a, b, c }
}

class BasicTests: MatchTests {
    func testEquatable() {
        XCTAssertEqual(Match(), Match())
        XCTAssertEqual(Match(any: P.a, P.b, all: Q.a, R.a),
                       Match(any: P.a, P.b, all: Q.a, R.a))
        XCTAssertEqual(Match(any: P.a, P.b, all: Q.a, R.a),
                       Match(any: P.b, P.a, all: R.a, Q.a))
        
        XCTAssertNotEqual(Match(any: P.a, P.b, all: Q.a, R.a),
                          Match(any: P.a, S.b, all: Q.a, R.a))
        XCTAssertNotEqual(Match(any: P.a, P.b, all: Q.a, R.a),
                          Match(any: P.a, P.b, all: Q.a, S.a))
        XCTAssertNotEqual(Match(any: P.a, P.b, P.b, all: Q.a, R.a),
                          Match(any: P.a, P.b, all: Q.a, R.a))
        XCTAssertNotEqual(Match(any: P.a, P.b, all: Q.a, R.a, R.a),
                          Match(any: P.a, P.b, all: Q.a, R.a))
    }
    
    func testSingleItemIsAll() {
        let match = Match(P.a)
        XCTAssertEqual(match.matchAll, [P.a.erase()])
        XCTAssertTrue(match.matchAny.isEmpty)
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
        XCTAssertEqual(Match() + Match(any: P.a, P.b),
                       Match(any: P.a, P.b))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(Match() + Match(P.a), Match(P.a))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = Match(any: P.a, P.b, all: Q.a, Q.b)
        XCTAssertEqual(Match() + addend, addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = Match(any: P.a, P.b)
        let m2 = Match(any: Q.a, Q.b)
        
        XCTAssertEqual(m1 + m2, Match(any: P.a, P.b, Q.a, Q.b))
    }
    
    func testAddingAlltoAny() {
        let m1 = Match(any: Q.a, Q.b)
        let m2 = Match(all: P.a, P.b)
        
        XCTAssertEqual(m1 + m2, Match(any: Q.a, Q.b,
                                      all: P.a, P.b))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = Match(any: Q.a, Q.b)
        let m2 = Match(any: R.a, R.b, all: P.a, P.b)
        
        XCTAssertEqual(m1 + m2, Match(any: Q.a, Q.b, R.a, R.b,
                                      all: P.a, P.b))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = Match(any: P.a, P.b, all: Q.a, Q.b)
        let m2 = Match(any: R.a, R.b, all: S.a, S.b)
        
        XCTAssertEqual(m1 + m2, Match(any: P.a, P.b, R.a, R.b,
                                      all: Q.a, Q.b, S.a, S.b))
    }
}

class FinalisationTests: MatchTests {
    func assertFinalise(_ m: Match, _ e: Match, line: UInt = #line) {
        XCTAssertEqual(e, try! m.finalise().get(), line: line)
    }

    func testMatchFinalisesToItself() {
        assertFinalise(Match(P.a),
                       Match(P.a))
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        assertFinalise(Match().prepend(Match(any: P.a, P.b)),
                       Match(any: P.a, P.b))
    }
    
    func testMatchWithNextFinalisesToSum() {
        assertFinalise(Match(any: P.a, P.b,
                             all: Q.a, R.a).prepend(Match(any: S.a, S.b,
                                                          all: T.a, U.a)),
                       Match(any: P.a, P.b, S.a, S.b,
                             all: Q.a, R.a, T.a, U.a))
    }
    
    func testLongChain() {
        var match = Match(P.a)
        
        100 * { match = match.prepend(Match()) }
        
        XCTAssertEqual(Match(P.a),
                       try! match.finalise().get())
    }
}

class ValidationTests: MatchTests {
    func assertDuplicateTypes(
        _ m1: Match,
        line: UInt = #line
    ) {
        assertThrows(m1, line: line) {
            guard let error = $0 as? DuplicateTypes else {
                XCTFail("Unexpected error \($0)", line: line)
                return
            }
            
            XCTAssertEqual(error,
                           DuplicateTypes(message: "P.a, P.b",
                                          files: [m1.file],
                                          lines: [m1.line]),
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
    
    func testAll_WithMultipleInstancesOfSameTypeIsError() {
        assertDuplicateTypes(Match(all: P.a, P.b))
    }
    
    func testAll_PrependedWithMultipleInstancesOfSameTypeIsError() {
        assertDuplicateTypes(Match().prepend(Match(all: P.a, P.b)))
    }
        
    func testAll_WithMultipleInstancesOfSameTypePrependedWithValidIsError() {
        assertDuplicateTypes(Match(all: P.a, P.b).prepend(Match()))
    }
    
    func assertCombinedDuplicateTypes(
        _ m1: Match,
        prepend m2: Match,
        line: UInt = #line
    ) {
        assertThrows(m1.prepend(m2), line: line) {
            guard let error = $0 as? DuplicateTypes else {
                XCTFail("Unexpected error \($0)", line: line)
                return
            }
            
            XCTAssertEqual(error,
                           DuplicateTypes(message: "P.a, P.b",
                                          files: [m1.file, m2.file],
                                          lines: [m1.line, m2.line]),
                           line: line)
        }
    }
    
    func testAll_CombinationFormingDuplicateTypesIsError() {
        assertCombinedDuplicateTypes(Match(P.a),
                                     prepend: Match(P.b))
    }
    
    func testAll_CombinationOfInvalidMatchesIsError() {
        assertCombinedDuplicateTypes(Match(all: P.a, P.b),
                                     prepend: Match(all: P.a, P.b))
    }
    
    func testAny_All_CombinationFormingDuplicateTypesIsError() {
        assertCombinedDuplicateTypes(Match(all: P.a, Q.a),
                                     prepend: Match(all: P.a, Q.a))
    }
    
    func assertDuplicateValues(
        _ m1: Match,
        prepend m2: Match? = nil,
        line: UInt = #line
    ) {
        let match = m2 == nil ? m1 : m1.prepend(m2!)
        let files = m2 == nil ? [m1.file] : [m1.file, m2!.file]
        let lines = m2 == nil ? [m1.line] : [m1.line, m2!.line]
        
        assertThrows(match, line: line) {
            guard let error = $0 as? DuplicateValues else {
                XCTFail("Unexpected error \($0)", line: line)
                return
            }
            
            XCTAssertEqual(error,
                           DuplicateValues(message: "P.a",
                                           files: files,
                                           lines: lines),
                           line: line)
        }
    }
    
    func testAny_CombinationFormingDuplicateValuesIsError() {
        assertDuplicateValues(Match(any: P.a, P.b),
                              prepend: Match(any: P.a, P.b))
    }
    
    func testAny_All_WithSamePredicateIsError() {
        assertDuplicateValues(Match(any: P.a, P.b, all: P.a, Q.a))
    }
}

class PermutationsTests: MatchTests {
    func testAllEmpty() {
        XCTAssertEqual(Match().allPredicatePermutations([]), [])
    }
    
    func assertPermutations(
        anyOf: [any PredicateProtocol] = [],
        allOf: [any PredicateProtocol] = [],
        with a: [[any PredicateProtocol]] = [],
        expected: [[any PredicateProtocol]],
        line: UInt = #line
    ) {
        let match = Match(any: anyOf, all: allOf)
        XCTAssertEqual(match.allPredicatePermutations(a.map { $0.erase() }.asSets),
                       expected.erasedSets,
                       line: line)
    }
    
    func testEmptyMatcher() {
        assertPermutations(expected: [])
    }
    
    func testAnyOfSinglePredicate() {
        assertPermutations(anyOf: [P.a], expected: [[P.a]])
    }
    
    func testAnyOfMultiPredicate() {
        assertPermutations(anyOf: [P.a, P.b], expected: [[P.a], [P.b]])
    }
    
    func testAllOfSingleType() {
        assertPermutations(allOf: [P.a], expected: [[P.a]])
    }
    
    func testAllOfMultiTypeM() {
        assertPermutations(allOf: [P.a, Q.a], expected: [[P.a, Q.a]])
    }
    
    func testCombinedAnyAndAll() {
        assertPermutations(anyOf: [R.a, R.b],
                           allOf: [P.a, Q.a],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b]])
    }
    
    func testEmptyMatcherWithSingleOther() {
        assertPermutations(with: [[P.a]],
                           expected: [[P.a]])
    }
    
    func testEmptyMatcherWithMultiOther() {
        assertPermutations(with: [[P.a, Q.a]],
                           expected: [[P.a, Q.a]])
    }
    
    func testEmptyMatcherWithMultiMultiOther() {
        assertPermutations(with: [[P.a, Q.a],
                                  [P.a, Q.b]],
                           expected: [[P.a, Q.a],
                                      [P.a, Q.b]])
    }
    
    func testAnyMatcherWithOther() {
        assertPermutations(anyOf: [P.a, P.b],
                           with: [[Q.a, R.a],
                                  [Q.b, R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.b, R.b],
                                      [P.b, Q.a, R.a],
                                      [P.b, Q.b, R.b]])
    }
    
    func testAllMatcherWithOther() {
        assertPermutations(allOf: [P.a, Q.a],
                           with: [[R.a],
                                  [R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b]])
    }
    
    func testAnyAndAllMatcherWithOther() {
        assertPermutations(anyOf: [Q.a, Q.b],
                           allOf: [P.a],
                           with: [[R.a],
                                  [R.b]],
                           expected: [[P.a, Q.a, R.a],
                                      [P.a, Q.a, R.b],
                                      [P.a, Q.b, R.a],
                                      [P.a, Q.b, R.b]])
    }
        
    func testAnyIgnoresTypesAlreadySpecified() {
        assertPermutations(anyOf: [P.a],
                           with: [[P.b, P.c, Q.a]],
                           expected: [[P.a, Q.a]])
    }
    
    func testAllIgnoresTypesAlreadySpecified() {
        assertPermutations(allOf: [P.a],
                           with: [[P.b, P.c, Q.a]],
                           expected: [[P.a, Q.a]])
    }
    
    func testAnyAllIgnoresTypesAlreadySpecified() {
        assertPermutations(anyOf: [P.a],
                           allOf: [R.a],
                           with: [[P.b, P.c, R.b, Q.a]],
                           expected: [[P.a, R.a, Q.a]])
    }
}

extension Match: CustomStringConvertible {
    public var description: String {
        "\(matchAny), \(matchAll)"
    }
}

extension Match: Equatable {
    public static func == (lhs: Match, rhs: Match) -> Bool {
        guard lhs.matchAny.count == rhs.matchAny.count else { return false }
        guard lhs.matchAll.count == rhs.matchAll.count else { return false }
        
        for any in lhs.matchAny {
            guard rhs.matchAny.contains(any) else { return false}
        }
        
        for all in lhs.matchAll {
            guard rhs.matchAll.contains(all) else { return false}
        }
        
        return true
    }
}

extension MatchError: CustomStringConvertible {
    public var description: String {
        "Message: \(message)\nFiles: \(files.map { URL(string: $0)!.lastPathComponent})\nLines: \(lines)"
    }
}

extension MatchError: Equatable {
    public static func == (lhs: MatchError, rhs: MatchError) -> Bool {
        lhs.files.sorted() == rhs.files.sorted() &&
        lhs.lines.sorted() == rhs.lines.sorted()
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
