import Testing
@testable import SwiftFSM

typealias Predicate = SwiftFSM.Predicate

private protocol NeverEqual { }; extension NeverEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { false }
}

private protocol AlwaysEqual { }; extension AlwaysEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

struct PredicateTests {
    enum NeverEqualPredicate: Predicate, NeverEqual   { case a }
    enum AlwaysEqualPredicate: Predicate, AlwaysEqual { case a }
    
    @Test func description() {
        #expect(
            NeverEqualPredicate.a.erased().description ==
            "NeverEqualPredicate.a"
        )
    }
    
    @Test func predicateInequality() {
        let p1 = NeverEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        #expect(p1 != p2)
    }

    @Test func predicateEquality() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = AlwaysEqualPredicate.a.erased()

        #expect(p1 == p2)
    }

    @Test func predicateFalseSet() {
        let p1 = NeverEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        #expect(2 == Set([p1, p2]).count)
    }

    @Test func predicateTrueSet() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = AlwaysEqualPredicate.a.erased()

        #expect(1 == Set([p1, p2]).count)
    }

    @Test func predicateDictionaryLookup() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        let a = [p1: "Pass"]
        let b = [p2: "Pass"]

        #expect(a[p1] == "Pass")
        #expect(a[p2] == nil)

        #expect(b[p1] == nil)
        #expect(b[p2] == nil)
    }

    @MainActor
    @Test func erasedWrapperUsesWrappedHasher() async {
        struct Spy: Predicate, NeverEqual {
            let confirm: @Sendable (Int) -> ()
            static var allCases: [Spy] { [] }
            func hash(into hasher: inout Hasher) { confirm(1) }
        }
        
        await confirmation { confirmation in
            let predicate = Spy(confirm: confirmation.confirm).erased()
            let _ = [predicate: "Pass"]
        }
    }
        
    @Test func basePreservesType() {
        let a1 = P.a.erased().unwrap(to: P.self)
        let a2 = P.a
        
        #expect(a1 == a2)
    }
    
    @Test func allCases() {
        #expect(P.a.allCases.erased() == P.allCases.erased())
        #expect(P.a.erased().allCases == P.allCases.erased())
    }
}

struct PredicateCombinationsTests {
    @Test func combinationsAccuracy() {
        enum P: Predicate { case a, b }
        enum Q: Predicate { case a, b }
        enum R: Predicate { case a, b }
        
        let predicates = [Q.a, Q.b, P.a, P.b, R.b, R.b].erased()
        
        let expected = [
            [P.a, Q.a, R.a],
            [P.b, Q.a, R.a],
            [P.a, Q.a, R.b],
            [P.b, Q.a, R.b],
            [P.a, Q.b, R.a],
            [P.b, Q.b, R.a],
            [P.a, Q.b, R.b],
            [P.b, Q.b, R.b]
        ].erasedSets
        
        #expect(expected == predicates.combinationsOfAllCases)
    }
    
    @Test func largeCombinations() {
        enum P: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        enum Q: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        enum R: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        
        let predicates = [Q.a, Q.b, P.a, P.b, R.b, R.b].erased()
        
        #expect(P.allCases.count * Q.allCases.count * R.allCases.count == // 1000, O(m^n)
                predicates.combinationsOfAllCases.count)
    }
}


