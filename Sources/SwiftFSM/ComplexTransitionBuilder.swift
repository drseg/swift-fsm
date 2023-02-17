//
//  ComplexTransitionBuilder.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 15/02/2023.
//

import Foundation
import Algorithms

protocol PredicateProtocol: CaseIterable, Hashable { }

extension PredicateProtocol {
    func isEqual(to rhs: any PredicateProtocol) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return rhs == self
    }
    
    var erase: AnyPredicate {
        AnyPredicate(base: self)
    }
    
    var allCases: [any PredicateProtocol] {
        Self.allCases as! [any PredicateProtocol]
    }
}

struct AnyPredicate: Hashable, CustomStringConvertible {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base.isEqual(to: rhs.base)
    }
    
    let base: any PredicateProtocol
    
    var description: String {
        String(describing: Swift.type(of: base)) +
        "." +
        String(describing: base)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

protocol ComplexTransitionBuilder: TransitionBuilder {
    associatedtype Predicate: PredicateProtocol
}

extension ComplexTransitionBuilder {
    func match(
        _ p: Predicate,
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        match(any: [p], rows: rows)
    }
    
    func match(
        any p: Predicate,
        _ ps: Predicate...,
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        match(any: [p] + ps, rows: rows)
    }
    
    func match(
        any p: [Predicate],
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) {
            if let wtap = $1.wtap {
                $0.append(WTAPRow(wtap: wtap.addMatch(Match(anyOf: p))))
            }
        }
    }
    
    func match(
        _ p: Predicate,
        @TAPBuilder<S> rows: () -> [TAPRow<S>]
    ) -> [TAPRow<S>] {
        match(any: [p], rows: rows)
    }
    
    func match(
        any p: Predicate,
        _ ps: Predicate...,
        @TAPBuilder<S> rows: () -> [TAPRow<S>]
    ) -> [TAPRow<S>] {
        match(any: [p] + ps, rows: rows)
    }
    
    func match(
        any p: [Predicate],
        @TAPBuilder<S> rows: () -> [TAPRow<S>]
    ) -> [TAPRow<S>] {
        rows().reduce(into: [TAPRow]()) {
            $0.append(TAPRow(tap: $1.tap.addMatch(Match(anyOf: p))))
        }
    }
    
    func match(
        _ p: Predicate,
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WAPRow<E>] {
        match(any: [p], rows: rows)
    }
    
    func match(
        any p: Predicate,
        _ ps: Predicate...,
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WAPRow<E>] {
        match(any: [p] + ps, rows: rows)
    }
    
    func match(
        any p: [Predicate],
        @WAPBuilder<E> rows: () -> [WAPRow<E>]
    ) -> [WAPRow<E>] {
        rows().reduce(into: [WAPRow]()) {
            $0.append(WAPRow(wap: $1.wap.addMatch(Match(anyOf: p))))
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
                           match: .none,
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
                  match: wap.match,
                  file: wap.file,
                  line: wap.line)
    }
    
    init(events: [E], tap: TAP<S>, file: String, line: Int) {
        self.init(events: events,
                  state: tap.state,
                  actions: tap.actions,
                  match: tap.match,
                  file: file,
                  line: line)
    }
    
    func addMatch(_ m: Match) -> Self {
        .init(events: events,
             state: state,
             actions: actions,
             match: match + m,
             file: file,
             line: line)
    }
}

extension TAP {
    func addMatch(_ m: Match) -> Self {
        .init(state: state,
              actions: actions,
              match: match + m)
    }
}

extension WAP {
    func addMatch(_ m: Match) -> Self {
        .init(events: events,
              actions: actions,
              match: match + m,
              file: file,
              line: line)
    }
}

extension Array where Element == any PredicateProtocol {
    var uniquePermutationsOfAllCases: Set<Set<AnyPredicate>> {
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
        map { $0.erase }
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

extension Match {
    typealias PredicateSets = Set<Set<AnyPredicate>>
    typealias PredicateArrays = [[AnyPredicate]]
    
    func emptySets() -> PredicateSets {
        Set(arrayLiteral: Set([AnyPredicate]()))
    }
    
    func allMatches(
        _ impliedPredicates: PredicateSets = []
    ) -> PredicateSets {
        let anyAndAll = anyOf.reduce(into: emptySets()) {
            $0.insert(Set(allOf + [$1]))
        }.removeEmpties ??? [allOf].asSets
        
        return impliedPredicates.reduce(into: emptySets()) { result, predicate in
            anyAndAll.forEach { result.insert(predicate.union($0)) }
        }.removeEmpties ??? impliedPredicates.asSets ??? anyAndAll
    }
}

infix operator ???: AdditionPrecedence

func ??? (
    lhs: Match.PredicateSets,
    rhs: Match.PredicateSets
) -> Match.PredicateSets {
    lhs.isEmpty ? rhs : lhs
}
