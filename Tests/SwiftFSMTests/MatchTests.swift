//
//  MatchTests.swift
//
//  Created by Daniel Segall on 22/02/2023.
//

import XCTest
@testable import SwiftFSM

class MatchTests: XCTestCase {
    // base types irrelevant as long as each row is uniquely typed
    let p1: AnyHashable = "P1",            p2: AnyHashable = "P2"
    let q1: AnyHashable = ["Q1": 1],       q2: AnyHashable = ["Q2": 2]
    let r1: AnyHashable = [1: "R1"],       r2: AnyHashable = [2: "R2"]
    let s1: AnyHashable = Substring("S1"), s2: AnyHashable = Substring("S2")
    let t1: AnyHashable = ["T1"],          t2: AnyHashable = ["T2"]
    let u1: AnyHashable = ["U1": "U1"],    u2: AnyHashable = ["U2": "U2"]
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
        XCTAssertEqual(Match(p1), try! match.finalise().get())
    }
}

class ValidationTests: MatchTests {
    func assert(match m: Match, is e: MatchError, line: UInt = #line) {
        XCTAssertThrowsError(try m.finalise().get(), line: line) {
            XCTAssertEqual(String(describing: type(of: $0)),
                           String(describing: type(of: e)),
                           line: line)
            XCTAssertEqual($0 as? MatchError, e, line: line)
        }
    }
    
    func assertHasDuplicateTypes(_ m1: Match, line: UInt = #line) {
        let error = DuplicateTypes(message: "p1, p2",
                                   files: [m1.file],
                                   lines: [m1.line])
        assert(match: m1, is: error, line: line)
    }
    
    func testAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(Match(all: p1, p2))
    }
    
    func testAll_AddingAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(Match().prepend(Match(all: p1, p2)))
        assertHasDuplicateTypes(Match(all: p1, p2).prepend(Match()))
    }
    
    func assertDuplicateTypesWhenAdded(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let error = DuplicateTypes(message: "p1, p2",
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
        let error =  DuplicateValues(message: "p1",
                                     files: [m.file],
                                     lines: [m.line])
        
        assert(match: m, is: error, line: line)
    }
    
    func testAny_All_WithSamePredicates() {
        assertHasDuplicateValues(Match(any: p1, p2, all: p1, q1))
    }
    
    func assertDuplicateValuesWhenAdded(_ m1: Match, _ m2: Match, line: UInt = #line) {
        let error =  DuplicateValues(message: "p1, p2",
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
}

extension Match: CustomStringConvertible {
    public var description: String {
        "\(matchAny), \(matchAll)"
    }
}

extension Match: Equatable {
    public static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.matchAny.count == rhs.matchAny.count &&
        lhs.matchAll.count == rhs.matchAll.count &&
        lhs.matchAny.allSatisfy({ rhs.matchAny.contains($0) }) &&
        lhs.matchAll.allSatisfy({ rhs.matchAll.contains($0) })
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

infix operator *

func * (lhs: Int, rhs: Action) {
    for _ in 1...lhs { rhs() }
}
