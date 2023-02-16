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
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        context(p, rows: rows)
    }
    
    func context(
        _ p: [Predicate],
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) {
            if let wtap = $1.wtap {
                $0.append(WTAPRow(wtap: wtap.addPredicates(p)))
            }
        }
    }
    
    func context(
        _ e: Event...,
        @TAPBuilder<S> rows: () -> [TAPRow<S>],
        file: String = #file,
        line: Int = #line
    ) -> [WTAPRow<S, E>] {
        context(e, rows: rows, file: file, line: line)
    }
    
    func context(
        _ e: [Event],
        @TAPBuilder<S> rows: () -> [TAPRow<S>],
        file: String = #file,
        line: Int = #line
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) {
            $0.append(WTAPRow(wtap: WTAP(events: e,
                                         tap: $1.tap,
                                         file: file,
                                         line: line)))
        }
    }
    
    func then() -> Then<S> {
        Then(state: nil)
    }
    
    func then(_ state: S) -> Then<S> {
        Then(state: state)
    }
    
    func then() -> TAPRow<S> {
        .empty
    }
    
    func then(_ state: S) -> TAPRow<S> {
        TAPRow(tap: TAP(state: state))
    }
}

struct Then<S: StateProtocol> {
    let state: S?
    
    static func | (lhs: Self, rhs: @escaping () -> ()) -> TAPRow<S> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> TAPRow<S> {
        TAPRow(tap: TAP(state: lhs.state, actions: rhs, predicates: []))
    }
}

extension WTAP {
    init(events: [E], tap: TAP<S>, file: String, line: Int) {
        self.init(events: events,
                  state: tap.state,
                  actions: tap.actions,
                  predicates: tap.predicates,
                  file: file,
                  line: line)
    }
    
    func addPredicates(_ p: [any PredicateProtocol]) -> Self {
        WTAP(events: events,
             state: state,
             actions: actions,
             predicates: predicates + p.map(\.erased),
             file: file,
             line: line)
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

