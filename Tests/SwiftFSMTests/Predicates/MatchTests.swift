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
    func testFileAndLineInit() {
        let f = "f", l = 1
        
        func assertFileAndLine(_ m: MatchDescriptor, line: UInt = #line) {
            XCTAssertEqual(f, m.file, line: line)
            XCTAssertEqual(l, m.line, line: line)
        }
        
        assertFileAndLine(MatchDescriptor(file: f, line: l))
        assertFileAndLine(MatchDescriptor(condition: { true }, file: f, line: l))
        assertFileAndLine(MatchDescriptor(any: p1, file: f, line: l))
        assertFileAndLine(MatchDescriptor(any: [[p1]], file: f, line: l))
        assertFileAndLine(MatchDescriptor(any: [p1.erased()], all: [], file: f, line: l))
        assertFileAndLine(MatchDescriptor(any: [[p1.erased()]], all: [], file: f, line: l))
    }
    
    @MainActor
    func testConditionInit() {
        XCTAssertEqual(nil, MatchDescriptor().condition?())
        XCTAssertEqual(true, MatchDescriptor(condition: { true }).condition?())
        XCTAssertEqual(false, MatchDescriptor(condition: { false }).condition?())
    }
    
    func testEquatable() {
        XCTAssertEqual(MatchDescriptor(), MatchDescriptor())
        
        XCTAssertEqual(MatchDescriptor(any: p1, p2, all: q1, r1),
                       MatchDescriptor(any: p1, p2, all: q1, r1))
        
        XCTAssertEqual(MatchDescriptor(any: p1, p2, all: q1, r1),
                       MatchDescriptor(any: p2, p1, all: r1, q1))
        
        XCTAssertEqual(MatchDescriptor(condition: { true }), MatchDescriptor(condition: { false }))
        
        XCTAssertNotEqual(MatchDescriptor(any: p1, p2, all: q1, r1),
                          MatchDescriptor(any: p1, s2, all: q1, r1))
        
        XCTAssertNotEqual(MatchDescriptor(any: p1, p2, all: q1, r1),
                          MatchDescriptor(any: p1, p2, all: q1, s1))
        
        XCTAssertNotEqual(MatchDescriptor(any: p1, p2, p2, all: q1, r1),
                          MatchDescriptor(any: p1, p2, all: q1, r1))
        
        XCTAssertNotEqual(MatchDescriptor(any: p1, p2, all: q1, r1, r1),
                          MatchDescriptor(any: p1, p2, all: q1, r1))
    }
}

class AdditionTests: MatchTests {
    func testAdditionTakesFileAndLineFromLHS() {
        let m1 = MatchDescriptor(file: "1", line: 1)
        let m2 = MatchDescriptor(file: "2", line: 2)
        
        XCTAssertEqual(m1.combineWith(m2).file, "1")
        XCTAssertEqual(m2.combineWith(m1).file, "2")
    
        XCTAssertEqual(m1.combineWith(m2).line, 1)
        XCTAssertEqual(m2.combineWith(m1).line, 2)
    }
    
    func testAddingEmptyMatches() {
        XCTAssertEqual(MatchDescriptor().combineWith(MatchDescriptor()), MatchDescriptor())
    }
    
    func testAddingAnyToEmpty() {
        XCTAssertEqual(MatchDescriptor().combineWith(MatchDescriptor(any: p1, p2)),
                       MatchDescriptor(any: p1, p2))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(MatchDescriptor().combineWith(MatchDescriptor(all: p1)), MatchDescriptor(all: p1))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = MatchDescriptor(any: p1, p2, all: q1, q2)
        XCTAssertEqual(MatchDescriptor().combineWith(addend), addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = MatchDescriptor(any: p1, p2)
        let m2 = MatchDescriptor(any: q1, q2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptor(any: [[p1, p2], [q1, q2]]))
    }
    
    func testAddingAlltoAny() {
        let m1 = MatchDescriptor(any: q1, q2)
        let m2 = MatchDescriptor(all: p1, p2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptor(any: q1, q2,
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = MatchDescriptor(any: q1, q2)
        let m2 = MatchDescriptor(any: r1, r2, all: p1, p2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptor(any: [[q1, q2], [r1, r2]],
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = MatchDescriptor(any: p1, p2, all: q1, q2)
        let m2 = MatchDescriptor(any: r1, r2, all: s1, s2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptor(any: [[p1, p2], [r1, r2]],
                                      all: q1, q2, s1, s2))
    }
    
    @MainActor
    func testAddingConditions() {
        let m1 = MatchDescriptor(condition: { true })
        let m2 = MatchDescriptor(condition: { false })
        let m3 = MatchDescriptor()
        
        XCTAssertEqual(true, m1.combineWith(m1).condition?())
        XCTAssertEqual(nil, m3.combineWith(m3).condition?())
        XCTAssertEqual(true, m1.combineWith(m3).condition?())
        
        XCTAssertEqual(false, m1.combineWith(m2).condition?())
        XCTAssertEqual(false, m2.combineWith(m3).condition?())
        XCTAssertEqual(false, m3.combineWith(m2).condition?())
    }
}

class FinalisationTests: MatchTests {
    func assertFinalise(_ m: MatchDescriptor, _ e: MatchDescriptor, line: UInt = #line) {
        XCTAssertEqual(e, try? m.resolve().get(), line: line)
    }

    func testMatchFinalisesToItself() {
        assertFinalise(MatchDescriptor(all: p1),
                       MatchDescriptor(all: p1))
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        assertFinalise(MatchDescriptor().prepend(MatchDescriptor(any: p1, p2)),
                       MatchDescriptor(any: p1, p2))
    }
    
    func testMatchWithNextFinalisesToSum() {
        assertFinalise(MatchDescriptor(any: p1, p2,
                             all: q1, r1).prepend(MatchDescriptor(any: s1, s2,
                                                        all: t1, u1)),
                       MatchDescriptor(any: [[p1, p2], [s1, s2]],
                             all: q1, r1, t1, u1))
    }
    
    func testPreservesMatchChain() {
        let result = try? MatchDescriptor().prepend(MatchDescriptor(any: p1, p2)).resolve().get()
        XCTAssertEqual(result, MatchDescriptor(any: p1, p2))
        XCTAssertEqual(result?.next, MatchDescriptor())
    }
    
    @MainActor
    func testLongChain() {
        var match = MatchDescriptor(all: p1)
        100 * { match = match.prepend(MatchDescriptor()) }
        XCTAssertEqual(MatchDescriptor(all: p1), try? match.resolve().get())
    }
}

class ValidationTests: MatchTests {
    func assert(match m: MatchDescriptor, is e: MatchError, line: UInt = #line) {
        XCTAssertThrowsError(try m.resolve().get(), line: line) {
            XCTAssertEqual(String(describing: type(of: $0)),
                           String(describing: type(of: e)),
                           line: line)
            XCTAssertEqual($0 as? MatchError, e, line: line)
        }
    }
    
    func assertHasDuplicateTypes(_ m1: MatchDescriptor, line: UInt = #line) {
        let error = DuplicateMatchTypes(predicates: [p1, p2].erased(),
                                        files: [m1.file],
                                        lines: [m1.line])
        assert(match: m1, is: error, line: line)
    }
    
    func testEmptyMatch() {
        XCTAssertEqual(MatchDescriptor().resolve(), .success(MatchDescriptor()))
    }
    
    func testAny_WithMultipleTypes() {
        assert(match: MatchDescriptor(any: p1, q1, file: "f", line: 1),
               is: ConflictingAnyTypes(predicates: [p1, q1].erased(),
                                       files: ["f"],
                                       lines: [1]))
    }
    
    func testAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptor(all: p1, p2))
    }
    
    func testAll_AddingAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptor().prepend(MatchDescriptor(all: p1, p2)))
        assertHasDuplicateTypes(MatchDescriptor(all: p1, p2).prepend(MatchDescriptor()))
    }
    
    func assertDuplicateTypesWhenAdded(_ m1: MatchDescriptor, _ m2: MatchDescriptor, line: UInt = #line) {
        let error = DuplicateMatchTypes(predicates: [p1, p2].erased(),
                                        files: [m1.file, m2.file],
                                        lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAllInvalid_AddingAllInvalid() {
        assertDuplicateTypesWhenAdded(MatchDescriptor(all: p1, p2),
                                      MatchDescriptor(all: p1, p2))
    }
    
    func testAll_AddingAll_FormingDuplicateTypes() {
        assertDuplicateTypesWhenAdded(MatchDescriptor(all: p1, q1),
                                      MatchDescriptor(all: p1, q1))
    }
    
    func testAny_All_WithSamePredicates() {
        let m = MatchDescriptor(any: p1, p2, all: p1, q1)
        let error = DuplicateAnyAllValues(predicates: [p1].erased(),
                                          files: [m.file],
                                          lines: [m.line])
        
        assert(match: m, is: error)
    }
    
    func assertDuplicateValuesWhenAdded<T: MatchError>(
        _ m1: MatchDescriptor,
        _ m2: MatchDescriptor,
        type: T.Type = DuplicateAnyValues.self,
        line: UInt = #line
    ) {
        let error =  type.init(predicates: [p1, p2].erased(),
                               files: [m1.file, m2.file],
                               lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAny_AddingAll_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(MatchDescriptor(any: p1, p2),
                                       MatchDescriptor(all: p1, q1),
                                       type: DuplicateAnyAllValues.self)
    }
    
    func testAny_AddingAny_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(MatchDescriptor(any: p1, p2),
                                       MatchDescriptor(any: p1, p2))
    }
    
    func testAnyAndAny_FormingDuplicateTypes() {
        let match = MatchDescriptor(any: [[p1], [p2], [p3]])

        assert(match: match, is: DuplicateMatchTypes(predicates: [p1, p2, p3].erased(),
                                                     files: [match.file],
                                                     lines: [match.line]))
    }
}

class MatchCombinationsTests: MatchTests {
    let predicatePool = [[Q.a, R.a, S.a],
                         [Q.b, R.a, S.a],
                         [Q.a, R.b, S.a],
                         [Q.b, R.b, S.a],
                         [Q.a, R.a, S.b],
                         [Q.b, R.a, S.b],
                         [Q.a, R.b, S.b],
                         [Q.b, R.b, S.b]].erasedSets

    func assertCombinations(
        match: MatchDescriptor,
        predicatePool: PredicateSets,
        expected: [[any Predicate]],
        eachRank: Int = 0,
        line: UInt = #line
    ) {
        let allCombinations = match.allPredicateCombinations(predicatePool)
        let allRanks = allCombinations.map(\.rank)
        let allPredicates = Set(allCombinations.map(\.predicates))
        
        XCTAssertEqual(allPredicates, expected.erasedSets, line: line)
        XCTAssertTrue(allRanks.allSatisfy { $0 == eachRank },
                      "expected \(eachRank), got \(allRanks)", line: line)
    }
    
    func testEmpties() {
        assertCombinations(match: MatchDescriptor(), predicatePool: [], expected: [])
        assertCombinations(match: MatchDescriptor(all: Q.a), predicatePool: [], expected: [])
    }
    
    func testNoMatch() {
        assertCombinations(match: MatchDescriptor(all: P.a),
                           predicatePool: predicatePool,
                           expected: [])
    }
    
    func testNoPredicateMatchesEntirePool() {
        assertCombinations(match: MatchDescriptor(),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.b, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b],
                                      [Q.a, R.b, S.b],
                                      [Q.b, R.b, S.b]])
    }
    
    func testAll_SinglePredicate() {
        assertCombinations(match: MatchDescriptor(all: Q.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.a, R.b, S.b]],
                           eachRank: 1)
    }
    
    func testAll_MultiPredicate() {
        assertCombinations(match: MatchDescriptor(all: Q.a, R.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.a, R.a, S.b]],
                           eachRank: 2)
        
        assertCombinations(match: MatchDescriptor(all: Q.a, R.a, S.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a]],
                           eachRank: 3)
    }
    
    func testAny_MultiPredicate() {
        assertCombinations(match: MatchDescriptor(any: Q.a, Q.b),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.b, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b],
                                      [Q.a, R.b, S.b],
                                      [Q.b, R.b, S.b]],
                           eachRank: 1)
        
        assertCombinations(match: MatchDescriptor(any: Q.a, R.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b],
                                      [Q.a, R.b, S.b]],
                           eachRank: 1)
    }
    
    func testMultiAny() {
        assertCombinations(match: MatchDescriptor(any: [[Q.a, Q.b], [R.a, R.b]]),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.b, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b],
                                      [Q.a, R.b, S.b],
                                      [Q.b, R.b, S.b]],
                           eachRank: 2)
    }
    
    func testAnyAndAll() {
        assertCombinations(match: MatchDescriptor(any: Q.a, Q.b, all: R.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b]],
                           eachRank: 2)
        
        assertCombinations(match: MatchDescriptor(any: Q.a, R.a, all: S.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a]],
                           eachRank: 2)
    }
}

extension MatchDescriptor: @retroactive CustomStringConvertible {
    public var description: String {
        "\(matchingAny), \(matchingAll)"
    }
}

extension MatchError: @retroactive CustomStringConvertible {
    public var description: String {
        String {
            "Predicates: \(predicates)"
            "Files: \(files.map { URL(string: $0)!.lastPathComponent})"
            "Lines: \(lines)"
        }
    }
}

extension MatchError: @retroactive Equatable {
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

@MainActor
func * (lhs: Int, rhs: FSMSyncAction) {
    for _ in 1...lhs { rhs() }
}
