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
    associatedtype Predicate: PredicateProtocol
}

extension ComplexTransitionBuilder {
    func context(
        _ p: Predicate...,
        @WTABuilder<S, E> rows: () -> [WTARow<S, E>]
    ) -> [WTAPRow<S, E>] {
        context(p, rows: rows)
    }

    func context(
        _ p: [Predicate],
        @WTABuilder<S, E> rows: () -> [WTARow<S, E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) { wtapRows, wtaRow in
            let wtap = WhensThenActionsPredicates(events: wtaRow.wta.events,
                                                  state: wtaRow.wta.state,
                                                  actions: wtaRow.wta.actions,
                                                  predicates: p.map(\.erased),
                                                  file: wtaRow.wta.file,
                                                  line: wtaRow.wta.line)
            
            wtapRows.append(WTAPRow(wtap: wtap))
        }
    }
    
#warning("duplicate code")
    func context(
        _ a1: @escaping () -> (),
        @WTBuilder<S, E> _ rows: () -> [WTRow<S, E>]
    ) -> [WTARow<S, E>] {
        context([a1], rows)
    }
    
    func context(
        _ a1: @escaping () -> (),
        _ a2: (() -> ())? = nil,
        _ a3: (() -> ())? = nil,
        _ a4: (() -> ())? = nil,
        _ a5: (() -> ())? = nil,
        _ a6: (() -> ())? = nil,
        _ a7: (() -> ())? = nil,
        _ a8: (() -> ())? = nil,
        _ a9: (() -> ())? = nil,
        _ a0: (() -> ())? = nil,
        @WTBuilder<S, E> _ rows: () -> [WTRow<S, E>]
    ) -> [WTARow<S, E>] {
        context(
            [a1, a2, a3, a4, a5, a6, a7, a8, a9, a0].compactMap { $0 },
            rows
        )
    }
    
    func context(
        _ actions: [() -> ()],
        @WTBuilder<S, E> _ rows: () -> [WTRow<S, E>]
    ) -> [WTARow<S, E>] {
        rows().reduce(into: [WTARow]()) { wtRows, wtRow in
            let wta = WhensThenActions(events: wtRow.wt.events,
                                       state: wtRow.wt.state,
                                       actions: actions,
                                       file: wtRow.wt.file,
                                       line: wtRow.wt.line)
            
            wtRows.append(WTARow(wta: wta))
        }
    }
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

