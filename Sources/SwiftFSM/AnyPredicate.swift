//
//  AnyPredicate.swift
//
//  Created by Daniel Segall on 21/02/2023.
//

import Foundation

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
    private let wrapped: AnyHashable
    
    init<P: PredicateProtocol>(base: P) {
        wrapped = AnyHashable(base)
    }
    
    func unwrap<P: PredicateProtocol>(to: P.Type) -> P {
        wrapped as! P
    }
    
    var allCases: [Self] {
        (wrapped as! any PredicateProtocol).allCases.erase()
    }
    
    var description: String {
        type + "." + String(describing: wrapped)
    }
    
    var type: String {
        String(describing: Swift.type(of: wrapped.base))
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

extension Collection where Element == AnyPredicate {
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
