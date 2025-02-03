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

class MatchDescriptorChainTests: XCTestCase {
    let p1 = P.a, p2 = P.b, p3 = P.c
    let q1 = Q.a, q2 = Q.b
    let r1 = R.a, r2 = R.b
    let s1 = S.a, s2 = S.b
    let t1 = T.a, t2 = T.b
    let u1 = U.a, u2 = U.b
}

class BasicTests: MatchDescriptorChainTests {
    func testFileAndLineInit() {
        let f = "f", l = 1
        
        func assertFileAndLine(_ m: MatchDescriptorChain, line: UInt = #line) {
            XCTAssertEqual(f, m.file, line: line)
            XCTAssertEqual(l, m.line, line: line)
        }
        
        assertFileAndLine(MatchDescriptorChain(file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(condition: { true }, file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: p1, file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [[p1]], file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [p1.erased()], all: [], file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [[p1.erased()]], all: [], file: f, line: l))
    }
    
    func testConditionInit() async {
        let c1 = await MatchDescriptorChain().condition?()
        XCTAssertEqual(nil, c1)
        let c2 = await MatchDescriptorChain(condition: { true }).condition?()
        XCTAssertEqual(true, c2)
        let c3 = await MatchDescriptorChain(condition: { false }).condition?()
        XCTAssertEqual(false, c3)
    }
    
    func testEquatable() {
        XCTAssertEqual(MatchDescriptorChain(), MatchDescriptorChain())
        
        XCTAssertEqual(MatchDescriptorChain(any: p1, p2, all: q1, r1),
                       MatchDescriptorChain(any: p1, p2, all: q1, r1))
        
        XCTAssertEqual(MatchDescriptorChain(any: p1, p2, all: q1, r1),
                       MatchDescriptorChain(any: p2, p1, all: r1, q1))
        
        XCTAssertEqual(MatchDescriptorChain(condition: { true }), MatchDescriptorChain(condition: { false }))
        
        XCTAssertNotEqual(MatchDescriptorChain(any: p1, p2, all: q1, r1),
                          MatchDescriptorChain(any: p1, s2, all: q1, r1))
        
        XCTAssertNotEqual(MatchDescriptorChain(any: p1, p2, all: q1, r1),
                          MatchDescriptorChain(any: p1, p2, all: q1, s1))
        
        XCTAssertNotEqual(MatchDescriptorChain(any: p1, p2, p2, all: q1, r1),
                          MatchDescriptorChain(any: p1, p2, all: q1, r1))
        
        XCTAssertNotEqual(MatchDescriptorChain(any: p1, p2, all: q1, r1, r1),
                          MatchDescriptorChain(any: p1, p2, all: q1, r1))
    }
}

class AdditionTests: MatchDescriptorChainTests {
    func testAdditionTakesFileAndLineFromLHS() {
        let m1 = MatchDescriptorChain(file: "1", line: 1)
        let m2 = MatchDescriptorChain(file: "2", line: 2)
        
        XCTAssertEqual(m1.combineWith(m2).file, "1")
        XCTAssertEqual(m2.combineWith(m1).file, "2")
    
        XCTAssertEqual(m1.combineWith(m2).line, 1)
        XCTAssertEqual(m2.combineWith(m1).line, 2)
    }
    
    func testAddingEmptyMatches() {
        XCTAssertEqual(MatchDescriptorChain().combineWith(MatchDescriptorChain()), MatchDescriptorChain())
    }
    
    func testAddingAnyToEmpty() {
        XCTAssertEqual(MatchDescriptorChain().combineWith(MatchDescriptorChain(any: p1, p2)),
                       MatchDescriptorChain(any: p1, p2))
    }
    
    func testAddingAllToEmpty() {
        XCTAssertEqual(MatchDescriptorChain().combineWith(MatchDescriptorChain(all: p1)), MatchDescriptorChain(all: p1))
    }
    
    func testAddingAnyAndAllToEmpty() {
        let addend = MatchDescriptorChain(any: p1, p2, all: q1, q2)
        XCTAssertEqual(MatchDescriptorChain().combineWith(addend), addend)
    }
    
    func testAddingAnytoAny() {
        let m1 = MatchDescriptorChain(any: p1, p2)
        let m2 = MatchDescriptorChain(any: q1, q2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptorChain(any: [[p1, p2], [q1, q2]]))
    }
    
    func testAddingAlltoAny() {
        let m1 = MatchDescriptorChain(any: q1, q2)
        let m2 = MatchDescriptorChain(all: p1, p2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptorChain(any: q1, q2,
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAlltoAny() {
        let m1 = MatchDescriptorChain(any: q1, q2)
        let m2 = MatchDescriptorChain(any: r1, r2, all: p1, p2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptorChain(any: [[q1, q2], [r1, r2]],
                                      all: p1, p2))
    }
    
    func testAddingAnyAndAllToAnyAndAll() {
        let m1 = MatchDescriptorChain(any: p1, p2, all: q1, q2)
        let m2 = MatchDescriptorChain(any: r1, r2, all: s1, s2)
        
        XCTAssertEqual(m1.combineWith(m2), MatchDescriptorChain(any: [[p1, p2], [r1, r2]],
                                      all: q1, q2, s1, s2))
    }
    
    func testAddingConditions() async {
        let m1 = MatchDescriptorChain(condition: { true })
        let m2 = MatchDescriptorChain(condition: { false })
        let m3 = MatchDescriptorChain()
        
        let c1 = await m1.combineWith(m1).condition?()
        XCTAssertEqual(true, c1)
        let c2 = await m3.combineWith(m3).condition?()
        XCTAssertEqual(nil, c2)
        let c3 = await m1.combineWith(m3).condition?()
        XCTAssertEqual(true, c3)
        
        let c4 = await m1.combineWith(m2).condition?()
        XCTAssertEqual(false, c4)
        let c5 = await m2.combineWith(m3).condition?()
        XCTAssertEqual(false, c5)
        let c6 = await m3.combineWith(m2).condition?()
        XCTAssertEqual(false, c6)
    }
}

class FinalisationTests: MatchDescriptorChainTests {
    func assertFinalise(_ m: MatchDescriptorChain, _ e: MatchDescriptorChain, line: UInt = #line) {
        XCTAssertEqual(e, try? m.resolve().get(), line: line)
    }

    func testMatchFinalisesToItself() {
        assertFinalise(MatchDescriptorChain(all: p1),
                       MatchDescriptorChain(all: p1))
    }

    func testEmptyMatchWithNextFinalisesToNext() {
        assertFinalise(MatchDescriptorChain().prepend(MatchDescriptorChain(any: p1, p2)),
                       MatchDescriptorChain(any: p1, p2))
    }
    
    func testMatchWithNextFinalisesToSum() {
        assertFinalise(MatchDescriptorChain(any: p1, p2,
                             all: q1, r1).prepend(MatchDescriptorChain(any: s1, s2,
                                                        all: t1, u1)),
                       MatchDescriptorChain(any: [[p1, p2], [s1, s2]],
                             all: q1, r1, t1, u1))
    }
    
    func testPreservesMatchChain() {
        let result = try? MatchDescriptorChain().prepend(MatchDescriptorChain(any: p1, p2)).resolve().get()
        XCTAssertEqual(result, MatchDescriptorChain(any: p1, p2))
        XCTAssertEqual(result?.childDescriptor, MatchDescriptorChain())
    }
    
    func testLongChain() {
        var match = MatchDescriptorChain(all: p1)
        (0..<100).forEach { _ in match = match.prepend(MatchDescriptorChain()) }
        XCTAssertEqual(MatchDescriptorChain(all: p1), try? match.resolve().get())
    }
}

class ValidationTests: MatchDescriptorChainTests {
    func assert(match m: MatchDescriptorChain, is e: MatchError, line: UInt = #line) {
        XCTAssertThrowsError(try m.resolve().get(), line: line) {
            XCTAssertEqual(String(describing: type(of: $0)),
                           String(describing: type(of: e)),
                           line: line)
            XCTAssertEqual($0 as? MatchError, e, line: line)
        }
    }
    
    func assertHasDuplicateTypes(_ m1: MatchDescriptorChain, line: UInt = #line) {
        let error = DuplicateMatchTypes(predicates: [p1, p2].erased(),
                                        files: [m1.file],
                                        lines: [m1.line])
        assert(match: m1, is: error, line: line)
    }
    
    func testEmptyMatch() {
        XCTAssertEqual(MatchDescriptorChain().resolve(), .success(MatchDescriptorChain()))
    }
    
    func testAny_WithMultipleTypes() {
        assert(match: MatchDescriptorChain(any: p1, q1, file: "f", line: 1),
               is: ConflictingAnyTypes(predicates: [p1, q1].erased(),
                                       files: ["f"],
                                       lines: [1]))
    }
    
    func testAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptorChain(all: p1, p2))
    }
    
    func testAll_AddingAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptorChain().prepend(MatchDescriptorChain(all: p1, p2)))
        assertHasDuplicateTypes(MatchDescriptorChain(all: p1, p2).prepend(MatchDescriptorChain()))
    }
    
    func assertDuplicateTypesWhenAdded(_ m1: MatchDescriptorChain, _ m2: MatchDescriptorChain, line: UInt = #line) {
        let error = DuplicateMatchTypes(predicates: [p1, p2].erased(),
                                        files: [m1.file, m2.file],
                                        lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAllInvalid_AddingAllInvalid() {
        assertDuplicateTypesWhenAdded(MatchDescriptorChain(all: p1, p2),
                                      MatchDescriptorChain(all: p1, p2))
    }
    
    func testAll_AddingAll_FormingDuplicateTypes() {
        assertDuplicateTypesWhenAdded(MatchDescriptorChain(all: p1, q1),
                                      MatchDescriptorChain(all: p1, q1))
    }
    
    func testAny_All_WithSamePredicates() {
        let m = MatchDescriptorChain(any: p1, p2, all: p1, q1)
        let error = DuplicateAnyAllValues(predicates: [p1].erased(),
                                          files: [m.file],
                                          lines: [m.line])
        
        assert(match: m, is: error)
    }
    
    func assertDuplicateValuesWhenAdded<T: MatchError>(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        type: T.Type = DuplicateAnyValues.self,
        line: UInt = #line
    ) {
        let error =  type.init(predicates: [p1, p2].erased(),
                               files: [m1.file, m2.file],
                               lines: [m1.line, m2.line])
        
        assert(match: m1.prepend(m2), is: error, line: line)
    }
    
    func testAny_AddingAll_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(MatchDescriptorChain(any: p1, p2),
                                       MatchDescriptorChain(all: p1, q1),
                                       type: DuplicateAnyAllValues.self)
    }
    
    func testAny_AddingAny_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(MatchDescriptorChain(any: p1, p2),
                                       MatchDescriptorChain(any: p1, p2))
    }
    
    func testAnyAndAny_FormingDuplicateTypes() {
        let match = MatchDescriptorChain(any: [[p1], [p2], [p3]])

        assert(match: match, is: DuplicateMatchTypes(predicates: [p1, p2, p3].erased(),
                                                     files: [match.file],
                                                     lines: [match.line]))
    }
}

class MatchCombinationsTests: MatchDescriptorChainTests {
    let predicatePool = [[Q.a, R.a, S.a],
                         [Q.b, R.a, S.a],
                         [Q.a, R.b, S.a],
                         [Q.b, R.b, S.a],
                         [Q.a, R.a, S.b],
                         [Q.b, R.a, S.b],
                         [Q.a, R.b, S.b],
                         [Q.b, R.b, S.b]].erasedSets

    func assertCombinations(
        match: MatchDescriptorChain,
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
        assertCombinations(match: MatchDescriptorChain(), predicatePool: [], expected: [])
        assertCombinations(match: MatchDescriptorChain(all: Q.a), predicatePool: [], expected: [])
    }
    
    func testNoMatch() {
        assertCombinations(match: MatchDescriptorChain(all: P.a),
                           predicatePool: predicatePool,
                           expected: [])
    }
    
    func testNoPredicateMatchesEntirePool() {
        assertCombinations(match: MatchDescriptorChain(),
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
        assertCombinations(match: MatchDescriptorChain(all: Q.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.a, R.b, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.a, R.b, S.b]],
                           eachRank: 1)
    }
    
    func testAll_MultiPredicate() {
        assertCombinations(match: MatchDescriptorChain(all: Q.a, R.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.a, R.a, S.b]],
                           eachRank: 2)
        
        assertCombinations(match: MatchDescriptorChain(all: Q.a, R.a, S.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a]],
                           eachRank: 3)
    }
    
    func testAny_MultiPredicate() {
        assertCombinations(match: MatchDescriptorChain(any: Q.a, Q.b),
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
        
        assertCombinations(match: MatchDescriptorChain(any: Q.a, R.a),
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
        assertCombinations(match: MatchDescriptorChain(any: [[Q.a, Q.b], [R.a, R.b]]),
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
        assertCombinations(match: MatchDescriptorChain(any: Q.a, Q.b, all: R.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.a, S.b],
                                      [Q.b, R.a, S.b]],
                           eachRank: 2)
        
        assertCombinations(match: MatchDescriptorChain(any: Q.a, R.a, all: S.a),
                           predicatePool: predicatePool,
                           expected: [[Q.a, R.a, S.a],
                                      [Q.b, R.a, S.a],
                                      [Q.a, R.b, S.a]],
                           eachRank: 2)
    }
}

extension MatchDescriptorChain: CustomStringConvertible {
    public var description: String {
        "\(matchingAny), \(matchingAll)"
    }
}

extension MatchError: CustomStringConvertible {
    public var description: String {
        String {
            "Predicates: \(predicates)"
            "Files: \(files.map { URL(string: $0)!.lastPathComponent})"
            "Lines: \(lines)"
        }
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
