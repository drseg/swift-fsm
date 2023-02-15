//
//  CharacterisationTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 15/02/2023.
//

import XCTest
import Algorithms
@testable import FiniteStateMachine

final class CharacterisationTests: XCTestCase {
    enum P1: PredicateProtocol {
        case a, b
    }
    
    enum P2: PredicateProtocol {
        case g, h
    }
    
    func testPermutations() {
        let states: [any PredicateProtocol] = [P2.g, P1.a]
        let expected: Set<Set<AnyPredicate>> = [[P2.g, P1.a].erased.s,
                                                [P2.g, P1.b].erased.s,
                                                [P2.h, P1.a].erased.s,
                                                [P2.h, P1.b].erased.s].s
        XCTAssertEqual(expected, states.uniqueAndTypedPermutations)
    }
}

extension Array where Element: Hashable {
    var s: Set<Self.Element> {
        Set(self)
    }
}

extension Array where Element == any PredicateProtocol {
    var uniqueAndTypedPermutations: Set<Set<AnyPredicate>> {
        Set(allPossibleCases
            .erased
            .uniquePermutations(ofCount: count)
            .map(Set.init)
            .filter(\.elementsAreUniquelyTyped)
        )
    }
    
    var allPossibleCases: [any PredicateProtocol] {
        map { $0.allCases }.flatten
    }

    var erased: [AnyPredicate] {
        map { $0.erased }
    }
}

extension Collection where Element == AnyPredicate {
    var elementsAreUniquelyTyped: Bool {
        uniqueElementTypes.count == count
    }
    
    var uniqueElementTypes: Set<String> {
        Set(map { String(describing: type(of: $0.base)) })
    }
}
