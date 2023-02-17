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
    func predicate(
        _ p: Predicate...,
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        predicate(p, rows: rows)
    }
    
    func predicate(
        _ p: [Predicate],
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) {
            if let wtap = $1.wtap {
                $0.append(WTAPRow(wtap: wtap.addPredicates(p)))
            }
        }
    }
    
    func predicate(
        _ p: Predicate...,
        @TAPBuilder<S> rows: () -> [TAPRow<S>]
    ) -> [TAPRow<S>] {
        predicate(p, rows: rows)
    }
    
    func predicate(
        _ p: [Predicate],
        @TAPBuilder<S> rows: () -> [TAPRow<S>]
    ) -> [TAPRow<S>] {
        rows().reduce(into: [TAPRow]()) {
            $0.append(TAPRow(tap: $1.tap.addPredicates(p)))
        }
    }
    
    func predicate(
        _ p: Predicate...,
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WAPRow<E>] {
        predicate(p, rows: rows)
    }
    
    func predicate(
        _ p: [Predicate],
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WAPRow<E>] {
        rows().reduce(into: [WAPRow]()) {
            $0.append(WAPRow(wap: $1.wap.addPredicates(p)))
        }
    }
    
    func when(
        _ e: Event...,
        file: String = #file,
        line: Int = #line
    ) -> WAPRow<E> {
        when(e, file: file, line: line)
    }
    
    func when(
        _ e: [Event],
        file: String = #file,
        line: Int = #line
    ) -> WAPRow<E> {
        WAPRow(wap: WAP<E>(events: e,
                           actions: [],
                           predicates: [],
                           file: file,
                           line: line))
    }
    
    func when(
        _ e: Event...,
        @TAPBuilder<S> rows: () -> [TAPRow<S>],
        file: String = #file,
        line: Int = #line
    ) -> [WTAPRow<S, E>] {
        when(e, rows: rows, file: file, line: line)
    }
    
    func when(
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
    
    func then(_ state: S) -> TAPRow<S> {
        TAPRow(tap: TAP(state: state))
    }
    
    func then(
        _ s: State,
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) {
            $0.append(WTAPRow(wtap: WTAP(state: s, wap: $1.wap)))
        }
    }
}

extension WTAP {
    init(state: S, wap: WAP<E>) {
        self.init(events: wap.events,
                  state: state,
                  actions: wap.actions,
                  predicates: wap.predicates,
                  file: wap.file,
                  line: wap.line)
    }
    
    init(events: [E], tap: TAP<S>, file: String, line: Int) {
        self.init(events: events,
                  state: tap.state,
                  actions: tap.actions,
                  predicates: tap.predicates,
                  file: file,
                  line: line)
    }
    
    func addPredicates(_ p: [any PredicateProtocol]) -> Self {
        .init(events: events,
             state: state,
             actions: actions,
             predicates: predicates + p.map(\.erased),
             file: file,
             line: line)
    }
}

extension TAP {
    func addPredicates(_ p: [any PredicateProtocol]) -> Self {
        .init(state: state,
              actions: actions,
              predicates: predicates + p.map(\.erased))
    }
}

extension WAP {
    func addPredicates(_ p: [any PredicateProtocol]) -> Self {
        .init(events: events,
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

