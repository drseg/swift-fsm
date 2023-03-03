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
    enum NeverEqualPredicate: PredicateProtocol, NeverEqual { case a, b }
    enum AlwaysEqualPredicate: PredicateProtocol, AlwaysEqual { case a, b }
    
    func testDescription() {
        XCTAssertEqual(NeverEqualPredicate.a.erase().description,
                       "NeverEqualPredicate.a")
    }

    func testPredicateInequality() {
        let p1 = NeverEqualPredicate.a.erase()
        let p2 = NeverEqualPredicate.a.erase()

        XCTAssertNotEqual(p1, p2)
    }

    func testPredicateEquality() {
        let p1 = AlwaysEqualPredicate.a.erase()
        let p2 = AlwaysEqualPredicate.a.erase()

        XCTAssertEqual(p1, p2)
    }

    func testPredicateFalseSet() {
        let p1 = NeverEqualPredicate.a.erase()
        let p2 = NeverEqualPredicate.a.erase()

        XCTAssertEqual(2, Set([p1, p2]).count)
    }

    func testPredicateTrueSet() {
        let p1 = AlwaysEqualPredicate.a.erase()
        let p2 = AlwaysEqualPredicate.a.erase()

        XCTAssertEqual(1, Set([p1, p2]).count)
    }

    func testPredicateDictionaryLookup() {
        let p1 = AlwaysEqualPredicate.a.erase()
        let p2 = NeverEqualPredicate.a.erase()

        let a = [p1: "Pass"]
        let b = [p2: "Pass"]

        XCTAssertEqual(a[p1], "Pass")
        XCTAssertNil(a[p2])

        XCTAssertNil(b[p1])
        XCTAssertNil(b[p2])
    }

    func testErasedWrapperUsesWrappedHasher() {
        struct Spy: PredicateProtocol, NeverEqual {
            let fulfill: () -> ()
            static var allCases: [Spy] { [Spy(fulfill: {})] }
            func hash(into hasher: inout Hasher) { fulfill() }
        }

        let e = expectation(description: "hash")
        let anyPredicate = Spy(fulfill: e.fulfill).erase()
        let _ = [anyPredicate: "Pass"]
        waitForExpectations(timeout: 0.1)
    }
        
    func testBasePreservesType() {
        let a1 = P.a.erase().unwrap(to: P.self)
        let a2 = P.a
        
        XCTAssertEqual(a1, a2)
    }
    
    func testAllCases() {
        XCTAssertEqual(P.a.allCases.erase(), P.allCases.erase())
        XCTAssertEqual(P.a.erase().allCases, P.allCases.erase())
    }
}

final class CombinationsTests: XCTestCase {
    func testPermutationsAccuracy() {
        enum P: PredicateProtocol { case a, b }
        enum Q: PredicateProtocol { case a, b }
        enum R: PredicateProtocol { case a, b }
        
        let predicates: [any PredicateProtocol] = [Q.a, Q.b, P.a, P.b, R.b, R.b]
        
        let expected = [[P.a, Q.a, R.a],
                        [P.b, Q.a, R.a],
                        [P.a, Q.a, R.b],
                        [P.b, Q.a, R.b],
                        [P.a, Q.b, R.a],
                        [P.b, Q.b, R.a],
                        [P.a, Q.b, R.b],
                        [P.b, Q.b, R.b]].erasedSets
        
        XCTAssertEqual(expected, predicates.uniquePermutationsOfAllCases)
    }
    
    func testLargePermutations() {
        enum P: PredicateProtocol { case a, b, c, d, e, f, g, h, i, j, k, l, m, n }
        enum Q: PredicateProtocol { case a, b, c, d, e, f, g, h, i, j, k, l, m, n }
        enum R: PredicateProtocol { case a, b, c, d, e, f, g, h, i, j, k, l, m, n }
        
        let predicates: [any PredicateProtocol] = [Q.a, Q.b, P.a, P.b, R.b, R.b]
        
        XCTAssertEqual(P.allCases.count * Q.allCases.count * R.allCases.count,
                       predicates.uniquePermutationsOfAllCases.count)
    }
}


