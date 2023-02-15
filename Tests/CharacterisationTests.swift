//
//  CharacterisationTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 15/02/2023.
//

import XCTest
@testable import FiniteStateMachine

final class CharacterisationTests: XCTestCase {
    enum P1: PredicateProtocol { case a, b }
    enum P2: PredicateProtocol { case g, h }
    enum P3: PredicateProtocol { case x, y }
    
    func testPermutations() {
        let states: [any PredicateProtocol] = [P2.g, P2.h, P1.a, P1.b, P3.y]
        
        let expected: Set<Set<AnyPredicate>> = [[P1.a, P2.g, P3.x].erased.s,
                                                [P1.b, P2.g, P3.x].erased.s,
                                                [P1.a, P2.g, P3.y].erased.s,
                                                [P1.b, P2.g, P3.y].erased.s,
                                                [P1.a, P2.h, P3.x].erased.s,
                                                [P1.b, P2.h, P3.x].erased.s,
                                                [P1.a, P2.h, P3.y].erased.s,
                                                [P1.b, P2.h, P3.y].erased.s,].s
        
        XCTAssertEqual(expected, states.uniquePermutationsOfElementCases)
    }
}

extension Array where Element: Hashable {
    var s: Set<Self.Element> {
        Set(self)
    }
}
