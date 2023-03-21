//
//  AnyPredicateTests.swift
//
//  Created by Daniel Segall on 21/02/2023.
//

import XCTest
@testable import SwiftFSM

private protocol NeverEqual { }; extension NeverEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { false }
}

private protocol AlwaysEqual { }; extension AlwaysEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

final class AnyPredicateTests: XCTestCase {
    enum NeverEqualPredicate: Predicate, NeverEqual   { case a }
    enum AlwaysEqualPredicate: Predicate, AlwaysEqual { case a }
    
    func testDescription() {
        XCTAssertEqual(NeverEqualPredicate.a.erased().description,
                       "NeverEqualPredicate.a")
    }

    func testPredicateInequality() {
        let p1 = NeverEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        XCTAssertNotEqual(p1, p2)
    }

    func testPredicateEquality() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = AlwaysEqualPredicate.a.erased()

        XCTAssertEqual(p1, p2)
    }

    func testPredicateFalseSet() {
        let p1 = NeverEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        XCTAssertEqual(2, Set([p1, p2]).count)
    }

    func testPredicateTrueSet() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = AlwaysEqualPredicate.a.erased()

        XCTAssertEqual(1, Set([p1, p2]).count)
    }

    func testPredicateDictionaryLookup() {
        let p1 = AlwaysEqualPredicate.a.erased()
        let p2 = NeverEqualPredicate.a.erased()

        let a = [p1: "Pass"]
        let b = [p2: "Pass"]

        XCTAssertEqual(a[p1], "Pass")
        XCTAssertNil(a[p2])

        XCTAssertNil(b[p1])
        XCTAssertNil(b[p2])
    }

    func testErasedWrapperUsesWrappedHasher() {
        struct Spy: Predicate, NeverEqual {
            let fulfill: () -> ()
            static var allCases: [Spy] { [Spy(fulfill: {})] }
            func hash(into hasher: inout Hasher) { fulfill() }
        }

        let e = expectation(description: "hash")
        let anyPredicate = Spy(fulfill: e.fulfill).erased()
        let _ = [anyPredicate: "Pass"]
        waitForExpectations(timeout: 0.1)
    }
        
    func testBasePreservesType() {
        let a1 = P.a.erased().unwrap(to: P.self)
        let a2 = P.a
        
        XCTAssertEqual(a1, a2)
    }
    
    func testAllCases() {
        XCTAssertEqual(P.a.allCases.erased(), P.allCases.erased())
        XCTAssertEqual(P.a.erased().allCases, P.allCases.erased())
    }
}

final class PredicateCombinationsTests: XCTestCase {
    func testCombinationsAccuracy() {
        enum P: Predicate { case a, b }
        enum Q: Predicate { case a, b }
        enum R: Predicate { case a, b }
        
        let predicates = [Q.a, Q.b, P.a, P.b, R.b, R.b].erased()
        
        let expected = [[P.a, Q.a, R.a],
                        [P.b, Q.a, R.a],
                        [P.a, Q.a, R.b],
                        [P.b, Q.a, R.b],
                        [P.a, Q.b, R.a],
                        [P.b, Q.b, R.a],
                        [P.a, Q.b, R.b],
                        [P.b, Q.b, R.b]].erasedSets
        
        XCTAssertEqual(expected, predicates.combinationsOfAllCases)
    }
    
    func testLargeCombinations() {
        enum P: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        enum Q: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        enum R: Predicate { case a, b, c, d, e, f, g, h, i, j, k, l, m, n } // 10
        
        let predicates = [Q.a, Q.b, P.a, P.b, R.b, R.b].erased()
        
        XCTAssertEqual(P.allCases.count * Q.allCases.count * R.allCases.count, // 1000, O(m*n)
                       predicates.combinationsOfAllCases.count)
    }
}


