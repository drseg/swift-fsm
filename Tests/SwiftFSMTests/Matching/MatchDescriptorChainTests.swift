import Testing
import Foundation
@testable import SwiftFSM

enum P: Predicate { case a, b, c }
enum Q: Predicate { case a, b    }
enum R: Predicate { case a, b    }
enum S: Predicate { case a, b    }
enum T: Predicate { case a, b    }
enum U: Predicate { case a, b    }
enum V: Predicate { case a, b    }
enum W: Predicate { case a, b    }

enum MatchDescriptorChainTests {
    class Base {
        let p1 = P.a, p2 = P.b, p3 = P.c
        let q1 = Q.a, q2 = Q.b
        let r1 = R.a, r2 = R.b
        let s1 = S.a, s2 = S.b
        let t1 = T.a, t2 = T.b
        let u1 = U.a, u2 = U.b
    }
}

extension MatchDescriptorChainTests {
    class BasicTests: Base { }
}

extension MatchDescriptorChainTests.BasicTests {
    @Test func fileAndLineInit() {
        let f = "f", l = 1
        
        func assertFileAndLine(
            _ m: MatchDescriptorChain,
            location: SourceLocation = #_sourceLocation
        ) {
            #expect(f == m.file, sourceLocation: location)
            #expect(l == m.line, sourceLocation: location)
        }
        
        assertFileAndLine(MatchDescriptorChain(file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(condition: { true }, file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: p1, file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [[p1]], file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [p1.erased()], all: [], file: f, line: l))
        assertFileAndLine(MatchDescriptorChain(any: [[p1.erased()]], all: [], file: f, line: l))
    }
    
    @Test func conditionInit() async {
        let c1 = MatchDescriptorChain().condition?()
        #expect(nil == c1)
        let c2 = MatchDescriptorChain(condition: { true }).condition?()
        #expect(true == c2)
        let c3 = MatchDescriptorChain(condition: { false }).condition?()
        #expect(false == c3)
    }
    
    @Test func equatable() {
        #expect(MatchDescriptorChain() == MatchDescriptorChain())
        
        #expect(MatchDescriptorChain(any: p1, p2, all: q1, r1) ==
                MatchDescriptorChain(any: p1, p2, all: q1, r1))
        
        #expect(MatchDescriptorChain(any: p1, p2, all: q1, r1) ==
                MatchDescriptorChain(any: p2, p1, all: r1, q1))
        
        #expect(
            MatchDescriptorChain(condition: { true }) == MatchDescriptorChain(condition: { false })
        )
        
        #expect(MatchDescriptorChain(any: p1, p2, all: q1, r1) !=
                MatchDescriptorChain(any: p1, s2, all: q1, r1))
        
        #expect(MatchDescriptorChain(any: p1, p2, all: q1, r1) !=
                MatchDescriptorChain(any: p1, p2, all: q1, s1))
        
        #expect(MatchDescriptorChain(any: p1, p2, p2, all: q1, r1) !=
                MatchDescriptorChain(any: p1, p2, all: q1, r1))
        
        #expect(MatchDescriptorChain(any: p1, p2, all: q1, r1, r1) !=
                MatchDescriptorChain(any: p1, p2, all: q1, r1))
    }
}

extension MatchDescriptorChainTests {
    class AdditionTests: Base { }
}

extension MatchDescriptorChainTests.AdditionTests {
    @Test func additionTakesFileAndLineFromLHS() {
        let m1 = MatchDescriptorChain(file: "1", line: 1)
        let m2 = MatchDescriptorChain(file: "2", line: 2)
        
        #expect(m1.combineWith(m2).file == "1")
        #expect(m2.combineWith(m1).file == "2")
        
        #expect(m1.combineWith(m2).line == 1)
        #expect(m2.combineWith(m1).line == 2)
    }
    
    @Test func addingEmptyMatches() {
        #expect(
            MatchDescriptorChain().combineWith(MatchDescriptorChain()) == MatchDescriptorChain()
        )
    }
    
    @Test func addingAnyToEmpty() {
        #expect(MatchDescriptorChain().combineWith(MatchDescriptorChain(any: p1, p2)) ==
                MatchDescriptorChain(any: p1, p2))
    }
    
    @Test func addingAllToEmpty() {
        #expect(
            MatchDescriptorChain().combineWith(MatchDescriptorChain(all: p1)) ==
            MatchDescriptorChain(all: p1)
        )
    }
    
    @Test func addingAnyAndAllToEmpty() {
        let addend = MatchDescriptorChain(any: p1, p2, all: q1, q2)
        #expect(MatchDescriptorChain().combineWith(addend) == addend)
    }
    
    @Test func addingAnytoAny() {
        let m1 = MatchDescriptorChain(any: p1, p2)
        let m2 = MatchDescriptorChain(any: q1, q2)
        
        #expect(m1.combineWith(m2) == MatchDescriptorChain(any: [[p1, p2], [q1, q2]]))
    }
    
    @Test func addingAlltoAny() {
        let m1 = MatchDescriptorChain(any: q1, q2)
        let m2 = MatchDescriptorChain(all: p1, p2)
        
        #expect(m1.combineWith(m2) == MatchDescriptorChain(any: q1, q2,
                                                           all: p1, p2))
    }
    
    @Test func addingAnyAndAlltoAny() {
        let m1 = MatchDescriptorChain(any: q1, q2)
        let m2 = MatchDescriptorChain(any: r1, r2, all: p1, p2)
        
        #expect(m1.combineWith(m2) == MatchDescriptorChain(any: [[q1, q2], [r1, r2]],
                                                           all: p1, p2))
    }
    
    @Test func addingAnyAndAllToAnyAndAll() {
        let m1 = MatchDescriptorChain(any: p1, p2, all: q1, q2)
        let m2 = MatchDescriptorChain(any: r1, r2, all: s1, s2)
        
        #expect(m1.combineWith(m2) == MatchDescriptorChain(any: [[p1, p2], [r1, r2]],
                                                           all: q1, q2, s1, s2))
    }
    
    @Test func addingConditions() async {
        let m1 = MatchDescriptorChain(condition: { true })
        let m2 = MatchDescriptorChain(condition: { false })
        let m3 = MatchDescriptorChain()
        
        let c1 = m1.combineWith(m1).condition?()
        #expect(true == c1)
        let c2 = m3.combineWith(m3).condition?()
        #expect(nil == c2)
        let c3 = m1.combineWith(m3).condition?()
        #expect(true == c3)
        
        let c4 = m1.combineWith(m2).condition?()
        #expect(false == c4)
        let c5 = m2.combineWith(m3).condition?()
        #expect(false == c5)
        let c6 = m3.combineWith(m2).condition?()
        #expect(false == c6)
    }
}

extension MatchDescriptorChainTests {
    class FinalisationTests: Base { }
}

extension MatchDescriptorChainTests.FinalisationTests {
    func assertFinalise(
        _ m: MatchDescriptorChain,
        _ e: MatchDescriptorChain,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(e == (try? m.resolve().get()), sourceLocation: location)
    }

    @Test func matchFinalisesToItself() {
        assertFinalise(MatchDescriptorChain(all: p1),
                       MatchDescriptorChain(all: p1))
    }

    @Test func emptyMatchWithNextFinalisesToNext() {
        assertFinalise(MatchDescriptorChain().prepend(MatchDescriptorChain(any: p1, p2)),
                       MatchDescriptorChain(any: p1, p2))
    }
    
    @Test func matchWithNextFinalisesToSum() {
        assertFinalise(MatchDescriptorChain(any: p1, p2,
                                            all: q1, r1).prepend(MatchDescriptorChain(any: s1, s2,
                                                                                      all: t1, u1)),
                       MatchDescriptorChain(any: [[p1, p2], [s1, s2]],
                                            all: q1, r1, t1, u1))
    }
    
    @Test func preservesMatchChain() {
        let result = try? MatchDescriptorChain().prepend(MatchDescriptorChain(any: p1, p2)).resolve().get()
        #expect(result == MatchDescriptorChain(any: p1, p2))
        #expect(result?.childDescriptor == MatchDescriptorChain())
    }
    
    @Test func longChain() {
        var match = MatchDescriptorChain(all: p1)
        (0..<100).forEach { _ in match = match.prepend(MatchDescriptorChain()) }
        #expect(MatchDescriptorChain(all: p1) == (try? match.resolve().get()))
    }
}

extension MatchDescriptorChainTests {
    class ValidationTests: Base { }
}

extension MatchDescriptorChainTests.ValidationTests {
    func assert(
        match m: MatchDescriptorChain,
        is e: MatchError,
        location: SourceLocation = #_sourceLocation
    ) {
        #expect(performing: {
            try m.resolve().get()
        }, throws: {
            #expect(
                String(describing: type(of: $0)) == String(describing: type(of: e)),
                sourceLocation: location
            )
            #expect($0 as? MatchError == e, sourceLocation: location)
            return true
        })
    }
    
    func assertHasDuplicateTypes(
        _ m1: MatchDescriptorChain,
        location: SourceLocation = #_sourceLocation
    ) {
        let error = DuplicateMatchTypes(predicates: [p1, p2].erased(),
                                        files: [m1.file],
                                        lines: [m1.line])
        assert(match: m1, is: error, location: location)
    }
    
    @Test func emptyMatch() {
        #expect(MatchDescriptorChain().resolve() == .success(MatchDescriptorChain()))
    }
    
    @Test func any_WithMultipleTypes() {
        assert(match: MatchDescriptorChain(any: p1, q1, file: "f", line: 1),
               is: ConflictingAnyTypes(predicates: [p1, q1].erased(),
                                       files: ["f"],
                                       lines: [1]))
    }
    
    @Test func all_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptorChain(all: p1, p2))
    }
    
    @Test func all_AddingAll_WithDuplicateTypes() {
        assertHasDuplicateTypes(MatchDescriptorChain().prepend(MatchDescriptorChain(all: p1, p2)))
        assertHasDuplicateTypes(MatchDescriptorChain(all: p1, p2).prepend(MatchDescriptorChain()))
    }
    
    func assertDuplicateTypesWhenAdded(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        location: SourceLocation = #_sourceLocation
    ) {
        let error = DuplicateMatchTypes(
            predicates: [p1, p2].erased(),
            files: [m1.file, m2.file],
            lines: [m1.line, m2.line]
        )
        
        assert(match: m1.prepend(m2), is: error, location: location)
    }
    
    @Test func allInvalid_AddingAllInvalid() {
        assertDuplicateTypesWhenAdded(
            MatchDescriptorChain(all: p1, p2),
            MatchDescriptorChain(all: p1, p2)
        )
    }
    
    @Test func all_AddingAll_FormingDuplicateTypes() {
        assertDuplicateTypesWhenAdded(
            MatchDescriptorChain(all: p1, q1),
            MatchDescriptorChain(all: p1, q1)
        )
    }
    
    @Test func any_All_WithSamePredicates() {
        let m = MatchDescriptorChain(any: p1, p2, all: p1, q1)
        let error = DuplicateAnyAllValues(
            predicates: [p1].erased(),
            files: [m.file],
            lines: [m.line]
        )
        
        assert(match: m, is: error)
    }
    
    func assertDuplicateValuesWhenAdded<T: MatchError>(
        _ m1: MatchDescriptorChain,
        _ m2: MatchDescriptorChain,
        type: T.Type = DuplicateAnyValues.self,
        location: SourceLocation = #_sourceLocation
    ) {
        let error =  type.init(
            predicates: [p1, p2].erased(),
            files: [m1.file, m2.file],
            lines: [m1.line, m2.line]
        )
        
        assert(match: m1.prepend(m2), is: error, location: location)
    }
    
    @Test func any_AddingAll_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(
            MatchDescriptorChain(any: p1, p2),
            MatchDescriptorChain(all: p1, q1),
            type: DuplicateAnyAllValues.self
        )
    }
    
    @Test func any_AddingAny_FormingDuplicateValues() {
        assertDuplicateValuesWhenAdded(
            MatchDescriptorChain(any: p1, p2),
            MatchDescriptorChain(any: p1, p2)
        )
    }
    
    @Test func anyAndAny_FormingDuplicateTypes() {
        let match = MatchDescriptorChain(any: [[p1], [p2], [p3]])

        assert(match: match, is: DuplicateMatchTypes(predicates: [p1, p2, p3].erased(),
                                                     files: [match.file],
                                                     lines: [match.line]))
    }
}

extension MatchDescriptorChainTests {
    class MatchCombinationsTests: Base {
        let predicatePool = [
            [Q.a, R.a, S.a],
            [Q.b, R.a, S.a],
            [Q.a, R.b, S.a],
            [Q.b, R.b, S.a],
            [Q.a, R.a, S.b],
            [Q.b, R.a, S.b],
            [Q.a, R.b, S.b],
            [Q.b, R.b, S.b]
        ].erasedSets
    }
}

extension MatchDescriptorChainTests.MatchCombinationsTests {
    func assertCombinations(
        match: MatchDescriptorChain,
        predicatePool: PredicateSets,
        expected: [[any Predicate]],
        eachRank: Int = 0,
        location: SourceLocation = #_sourceLocation
    ) {
        let allCombinations = match.allPredicateCombinations(predicatePool)
        let allRanks = allCombinations.map(\.rank)
        let allPredicates = Set(allCombinations.map(\.predicates))
        
        #expect(allPredicates == expected.erasedSets, sourceLocation: location)
        #expect(
            allRanks.allSatisfy { $0 == eachRank },
            "expected \(eachRank), got \(allRanks)",
            sourceLocation: location
        )
    }
    
    @Test func empties() {
        assertCombinations(match: MatchDescriptorChain(), predicatePool: [], expected: [])
        assertCombinations(match: MatchDescriptorChain(all: Q.a), predicatePool: [], expected: [])
    }
    
    @Test func noMatch() {
        assertCombinations(match: MatchDescriptorChain(all: P.a),
                           predicatePool: predicatePool,
                           expected: [])
    }
    
    @Test func noPredicateMatchesEntirePool() {
        assertCombinations(
            match: MatchDescriptorChain(),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.b, S.a],
                [Q.b, R.b, S.a],
                [Q.a, R.a, S.b],
                [Q.b, R.a, S.b],
                [Q.a, R.b, S.b],
                [Q.b, R.b, S.b]
            ]
        )
    }
    
    @Test func all_SinglePredicate() {
        assertCombinations(
            match: MatchDescriptorChain(all: Q.a),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.a, R.b, S.a],
                [Q.a, R.a, S.b],
                [Q.a, R.b, S.b]
            ],
            eachRank: 1
        )
    }
    
    @Test func all_MultiPredicate() {
        assertCombinations(
            match: MatchDescriptorChain(all: Q.a, R.a),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.a, R.a, S.b]
            ],
            eachRank: 2
        )
        
        assertCombinations(
            match: MatchDescriptorChain(all: Q.a, R.a, S.a),
            predicatePool: predicatePool,
            expected: [[Q.a, R.a, S.a]],
            eachRank: 3
        )
    }
    
    @Test func any_MultiPredicate() {
        assertCombinations(
            match: MatchDescriptorChain(any: Q.a, Q.b),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.b, S.a],
                [Q.b, R.b, S.a],
                [Q.a, R.a, S.b],
                [Q.b, R.a, S.b],
                [Q.a, R.b, S.b],
                [Q.b, R.b, S.b]
            ],
            eachRank: 1
        )
        
        assertCombinations(
            match: MatchDescriptorChain(any: Q.a, R.a),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.b, S.a],
                [Q.a, R.a, S.b],
                [Q.b, R.a, S.b],
                [Q.a, R.b, S.b]
            ],
            eachRank: 1
        )
    }
    
    @Test func multiAny() {
        assertCombinations(
            match: MatchDescriptorChain(any: [[Q.a, Q.b], [R.a, R.b]]),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.b, S.a],
                [Q.b, R.b, S.a],
                [Q.a, R.a, S.b],
                [Q.b, R.a, S.b],
                [Q.a, R.b, S.b],
                [Q.b, R.b, S.b]
            ],
            eachRank: 2
        )
    }
    
    @Test func anyAndAll() {
        assertCombinations(
            match: MatchDescriptorChain(any: Q.a, Q.b, all: R.a),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.a, S.b],
                [Q.b, R.a, S.b]
            ],
            eachRank: 2
        )
        
        assertCombinations(
            match: MatchDescriptorChain(any: Q.a, R.a, all: S.a),
            predicatePool: predicatePool,
            expected: [
                [Q.a, R.a, S.a],
                [Q.b, R.a, S.a],
                [Q.a, R.b, S.a]
            ],
            eachRank: 2
        )
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
