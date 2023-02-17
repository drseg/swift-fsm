//
//  UnsafeTests.swift
//
//  Created by Daniel Segall on 29/01/2023.
//

import XCTest
@testable import FiniteStateMachine

private protocol NeverEqual { }; extension NeverEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { false }
}

private protocol AlwaysEqual { }; extension AlwaysEqual {
    static func == (lhs: Self, rhs: Self) -> Bool { true }
}

final class ErasedHashableConformanceTests: XCTestCase {
    enum NeverEqualPredicate: PredicateProtocol, NeverEqual { case a }
    enum AlwaysEqualPredicate: PredicateProtocol, AlwaysEqual { case a }

    func testStateInequality() {
        let s1 = NeverEqualPredicate.a.erase
        let s2 = NeverEqualPredicate.a.erase

        XCTAssertNotEqual(s1, s2)
    }

    func testStateEquality() {
        let s1 = AlwaysEqualPredicate.a.erase
        let s2 = AlwaysEqualPredicate.a.erase

        XCTAssertEqual(s1, s2)
    }

    func testStateFalseSet() {
        let s1 = NeverEqualPredicate.a.erase
        let s2 = NeverEqualPredicate.a.erase

        XCTAssertEqual(2, Set([s1, s2]).count)
    }

    func testStateTrueSet() {
        let s1 = AlwaysEqualPredicate.a.erase
        let s2 = AlwaysEqualPredicate.a.erase

        XCTAssertEqual(1, Set([s1, s2]).count)
    }

    func testStateDictionaryLookup() {
        let s1 = AlwaysEqualPredicate.a.erase
        let s2 = NeverEqualPredicate.a.erase

        let a = [s1: "Pass"]
        let b = [s2: "Pass"]

        XCTAssertEqual(a[s1], "Pass")
        XCTAssertNil(a[s2])

        XCTAssertNil(b[s2])
        XCTAssertNil(b[s1])
    }

    func testErasedWrapperUsesWrappedHasher() {
        struct StateSpy: PredicateProtocol, Hashable, NeverEqual {
            let callback: () -> ()
            static var allCases: [StateSpy] { [StateSpy(callback: {})] }
            func hash(into hasher: inout Hasher) { callback() }
        }

        let e = expectation(description: "hash")
        let wrapper = StateSpy() { e.fulfill() }.erase
        let _ = [wrapper: "Pass"]
        waitForExpectations(timeout: 0.1)
    }
}
