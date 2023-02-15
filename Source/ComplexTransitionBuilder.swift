//
//  ComplexTransitionBuilder.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 15/02/2023.
//

import Foundation
import Algorithms

protocol PredicateProtocol: CaseIterable, Hashable { }

typealias PP = PredicateProtocol

extension PredicateProtocol {
    func isEqual(to rhs: any PredicateProtocol) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return rhs == self
    }
    
    var erased: AnyPredicate {
        AnyPredicate(base: self)
    }
    
    var allCases: [any PredicateProtocol] {
        Self.allCases as! [any PredicateProtocol]
    }
}

struct AnyPredicate: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base.isEqual(to: rhs.base)
    }
    
    let base: any PredicateProtocol
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

protocol ComplexTransitionBuilder: TransitionBuilder {
    
}

extension Array where Element == any PredicateProtocol {
    var uniquePermutationsOfElementCases: Set<Set<AnyPredicate>> {
        return Set(
            uniqueTypes
                .allPossibleCases
                .erased
                .uniquePermutations(ofCount: uniqueTypes.count)
                .map(Set.init)
                .filter(\.elementsAreUniquelyTyped)
        )
    }
    
    var uniqueTypes: [AnyPredicate] {
        let erased = self.erased
        return erased.uniqueElementTypes.reduce(
            into: [AnyPredicate]()
        ) { predicates, type in
            predicates.append(erased.first { $0.type == type }!)
        }
    }
    
    var erased: [AnyPredicate] {
        map { $0.erased }
    }
}

extension Collection where Element == AnyPredicate {
    var allPossibleCases: [any PredicateProtocol] {
        map { $0.base.allCases }.flatten
    }
    
    var elementsAreUniquelyTyped: Bool {
        uniqueElementTypes.count == count
    }
    
    var uniqueElementTypes: Set<String> {
        Set(map(\.type))
    }
}

extension AnyPredicate {
    var type: String {
        String(describing: Swift.type(of: base))
    }
}

