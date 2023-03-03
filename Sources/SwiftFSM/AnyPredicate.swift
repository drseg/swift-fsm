//
//  AnyPredicate.swift
//
//  Created by Daniel Segall on 21/02/2023.
//

import Foundation
import Algorithms

typealias PredicateSets = Set<PredicateSet>
typealias PredicateSet = Set<AnyPredicate>

protocol PredicateProtocol: CaseIterable, Hashable { }

extension PredicateProtocol {
    func erase() -> AnyPredicate {
        AnyPredicate(base: self)
    }
    
    var allCases: [any PredicateProtocol] {
        Self.allCases as! [any PredicateProtocol]
    }
}

struct AnyPredicate: CustomStringConvertible, Hashable {
    private let base: AnyHashable
    
    init<P: PredicateProtocol>(base: P) {
        self.base = AnyHashable(base)
    }
    
    func unwrap<P: PredicateProtocol>(to: P.Type) -> P {
        base as! P
    }
    
    var allCases: [Self] {
        (base as! any PredicateProtocol).allCases.erase()
    }
    
    var description: String {
        type + "." + String(describing: base)
    }
    
    var type: String {
        String(describing: Swift.type(of: base.base))
    }
}

extension Array {
    func erase() -> [AnyPredicate] where Element: PredicateProtocol {
        _erase()
    }
    
    func erase() -> [AnyPredicate] where Element == any PredicateProtocol {
        _erase()
    }
    
    private func _erase() -> [AnyPredicate] {
        map { ($0 as! any PredicateProtocol).erase() }
    }
}

extension Collection where Element == any PredicateProtocol {
    var uniquePermutationsOfAllCases: PredicateSets {
        Set(uniqueTypes
            .allPossibleCases
            .combinations(ofCount: uniqueTypes.count)
            .map(Set.init)
            .filter(\.elementsAreUniquelyTyped)
        )
    }
    
    var uniqueTypes: [AnyPredicate] {
        let erased = erase()
        return erased.uniqueElementTypes.reduce(
            into: [AnyPredicate]()
        ) { predicates, type in
            predicates.append(erased.first { $0.type == type }!)
        }
    }
    
    func erase() -> [AnyPredicate] {
        map { $0.erase() }
    }
}


extension Collection where Element == AnyPredicate {
    var allPossibleCases: [AnyPredicate] {
        map { $0.allCases }.flattened
    }
    
    var elementsAreUnique: Bool {
        Set(self).count == count
    }
    
    var elementsAreUniquelyTyped: Bool {
        uniqueElementTypes.count == count
    }
    
    var uniqueElementTypes: Set<String> {
        Set(map(\.type))
    }
}
