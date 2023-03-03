//
//  AnyPredicate.swift
//
//  Created by Daniel Segall on 21/02/2023.
//

import Foundation
import Algorithms

typealias PredicateSets = Set<PredicateSet>
typealias PredicateSet = Set<AnyPredicate>

protocol Predicate: CaseIterable, Hashable { }

extension Predicate {
    func erase() -> AnyPredicate {
        AnyPredicate(base: self)
    }
    
    var allCases: [any Predicate] {
        Self.allCases as! [any Predicate]
    }
}

struct AnyPredicate: CustomStringConvertible, Hashable {
    private let base: AnyHashable
    
    init<P: Predicate>(base: P) {
        self.base = AnyHashable(base)
    }
    
    func unwrap<P: Predicate>(to: P.Type) -> P {
        base as! P
    }
    
    var allCases: [Self] {
        (base as! any Predicate).allCases.erase()
    }
    
    var description: String {
        type + "." + String(describing: base)
    }
    
    var type: String {
        String(describing: Swift.type(of: base.base))
    }
}

extension Array {
    func erase() -> [AnyPredicate] where Element: Predicate       { _erase() }
    func erase() -> [AnyPredicate] where Element == any Predicate { _erase() }
    
    private func _erase() -> [AnyPredicate] {
        map { ($0 as! any Predicate).erase() }
    }
}

extension Collection where Element == AnyPredicate {
    var combinationsOfAllCases: PredicateSets {
        let uniqueTypes = uniqueTypes
        
        return Set(uniqueTypes
            .allPossibleCases
            .combinations(ofCount: uniqueTypes.count)
            .map(Set.init)
            .filter(\.elementsAreUniquelyTyped)
        )
    }
    
    var uniqueTypes: [AnyPredicate] {
        uniqueElementTypes.reduce(into: [AnyPredicate]()) { predicates, type in
            predicates.append(first { $0.type == type }!)
        }
    }
    
    var allPossibleCases: [AnyPredicate] {
        map(\.allCases).flattened
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
