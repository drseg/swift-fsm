//
//  MatchTests.swift
//
//  Created by Daniel Segall on 22/02/2023.
//

import XCTest
@testable import SwiftFSM

class MatchTests: XCTestCase {
    let p1: AnyHashable = "P1",         p2: AnyHashable = "P2"
    let q1: AnyHashable = 1,            q2: AnyHashable = 2
    let r1: AnyHashable = 1.1,          r2: AnyHashable = 2.2
    let s1: AnyHashable = true,         s2: AnyHashable = false
    let t1: AnyHashable = ["T1"],       t2: AnyHashable = ["T2"]
    let u1: AnyHashable = ["U1": "U1"], u2: AnyHashable = ["U2": "U2"]
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
    
    func testSingleItemIsAll() {
        let match = Match(p1)
        XCTAssertEqual(match.matchAll, [p1])
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
        XCTAssertEqual(Match() + Match(any: p1, p2),
                       Match(any: p1, p2))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(Match() + Match(p1), Match(p1))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = Match(any: p1, p2, all: q1, q2)
        XCTAssertEqual(Match() + addend, addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = Match(any: p1, p2)
        let m2 = Match(any: q1, q2)
        
        XCTAssertEqual(m1 + m2, Match(any: p1, p2, q1, q2))
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
        
        XCTAssertEqual(m1 + m2, Match(any: q1, q2, r1, r2,
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = Match(any: p1, p2, all: q1, q2)
        let m2 = Match(any: r1, r2, all: s1, s2)
        
        XCTAssertEqual(m1 + m2, Match(any: p1, p2, r1, r2,
                                      all: q1, q2, s1, s2))
    }
}

class FinalisationTests: MatchTests {
    func assertFinalise(_ m: Match, _ e: Match, line: UInt = #line) {
        XCTAssertEqual(e, try! m.finalise().get(), line: line)
    }

    func testMatchFinalisesToItself() {
        assertFinalise(Match(p1),
                       Match(p1))
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        assertFinalise(Match().prepend(Match(any: p1, p2)),
                       Match(any: p1, p2))
    }
    
    func testMatchWithNextFinalisesToSum() {
        assertFinalise(Match(any: p1, p2,
                             all: q1, r1).prepend(Match(any: s1, s2,
                                                        all: t1, u1)),
                       Match(any: p1, p2, s1, s2,
                             all: q1, r1, t1, u1))
    }
    
    func testLongChain() {
        var match = Match(p1)
        
        100 * { match = match.prepend(Match()) }
        
        XCTAssertEqual(Match(p1),
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
                           DuplicateTypes(message: "p1, p2",
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
        assertDuplicateTypes(Match(all: p1, p2))
    }
    
    func testAll_PrependedWithMultipleInstancesOfSameTypeIsError() {
        assertDuplicateTypes(Match().prepend(Match(all: p1, p2)))
    }
        
    func testAll_WithMultipleInstancesOfSameTypePrependedWithValidIsError() {
        assertDuplicateTypes(Match(all: p1, p2).prepend(Match()))
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
                           DuplicateTypes(message: "p1, p2",
                                          files: [m1.file, m2.file],
                                          lines: [m1.line, m2.line]),
                           line: line)
        }
    }
    
    func testAll_CombinationFormingDuplicateTypesIsError() {
        assertCombinedDuplicateTypes(Match(p1),
                                     prepend: Match(p2))
    }
    
    func testAll_CombinationOfInvalidMatchesIsError() {
        assertCombinedDuplicateTypes(Match(all: p1, p2),
                                     prepend: Match(all: p1, p2))
    }
    
    func testAny_All_CombinationFormingDuplicateTypesIsError() {
        assertCombinedDuplicateTypes(Match(all: p1, q1),
                                     prepend: Match(all: p1, q1))
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
                           DuplicateValues(message: "p1",
                                           files: files,
                                           lines: lines),
                           line: line)
        }
    }
    
    func testAny_CombinationFormingDuplicateValuesIsError() {
        assertDuplicateValues(Match(any: p1, p2),
                              prepend: Match(any: p1, p2))
    }
    
    func testAny_All_WithSamePredicateIsError() {
        assertDuplicateValues(Match(any: p1, p2, all: p1, q1))
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

infix operator *

func * (lhs: Int, rhs: Action) {
    for _ in 1...lhs {
        rhs()
    }
}
