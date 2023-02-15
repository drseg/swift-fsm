//
//  CharacterisationTests.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 15/02/2023.
//

import XCTest
@testable import FiniteStateMachine

final class ComplexTransitionBuilderTests: TestingBase, ComplexTransitionBuilder {
    
}

final class CharacterisationTests: XCTestCase {
    enum P1: PredicateProtocol { case a, b }
    enum P2: PredicateProtocol { case g, h }
    enum P3: PredicateProtocol { case x, y }
    
    func testPermutations() {
        let states: [any PredicateProtocol] = [P2.g, P2.h, P1.a, P1.b, P3.y]
        
        let expected = [[P1.a, P2.g, P3.x],
                        [P1.b, P2.g, P3.x],
                        [P1.a, P2.g, P3.y],
                        [P1.b, P2.g, P3.y],
                        [P1.a, P2.h, P3.x],
                        [P1.b, P2.h, P3.x],
                        [P1.a, P2.h, P3.y],
                        [P1.b, P2.h, P3.y]].s
        
        XCTAssertEqual(expected, states.uniquePermutationsOfElementCases)
    }
}

extension Array where Element == [any PredicateProtocol] {
    var s: Set<Set<AnyPredicate>> {
        map { $0.erased.s }.s
    }
}

extension Array where Element: Hashable {
    var s: Set<Self.Element> {
        Set(self)
    }
}

