//
//  AnyPredicate.swift
//
//  Created by Daniel Segall on 21/02/2023.
//

import Foundation

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
    private let wrapped: AnyHashable
    
    init<P: Predicate>(base: P) {
        wrapped = AnyHashable(base)
    }
    
    func unwrap<P: Predicate>(to: P.Type) -> P {
        wrapped as! P
    }
    
    var allCases: [Self] {
        (wrapped as! any Predicate).allCases.erase()
    }
    
    var description: String {
        type + "." + String(describing: wrapped)
    }
    
    var type: String {
        String(describing: Swift.type(of: wrapped.base))
    }
}

extension Array {
    func erase() -> [AnyPredicate] where Element: Predicate {
        _erase()
    }
    
    func erase() -> [AnyPredicate] where Element == any Predicate {
        _erase()
    }
    
    private func _erase() -> [AnyPredicate] {
        map { ($0 as! any Predicate).erase() }
    }
}
