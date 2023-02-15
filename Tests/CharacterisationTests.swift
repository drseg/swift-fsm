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
                                                [P2.h, P1.b].erased.s
        ].s
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
        let uniqueTypes = Set(map { String(describing: type(of: $0)) })
        
        return Set(
            allCases
                .erased
                .uniquePermutations(ofCount: count)
                .map(Set.init)
                .filter {
                    Set($0.map {
                        String(describing: type(of: $0.base))
                    }).count == $0.count
                }
        )
    }
    
    var allCases: [any PredicateProtocol] {
        map { $0.allCases }.flatten
    }

    var erased: [AnyPredicate] {
        map { $0.erased }
    }
}
