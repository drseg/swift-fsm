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
    
    func erase() -> AnyPredicate {
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
        type + "." + String(describing: base)
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
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        match(anyOf: [p], rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        match(anyOf: [p] + ps, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        rows().reduce(into: [WTAMRow]()) {
            if let wtam = $1.wtam {
                $0.append(WTAMRow(wtam: wtam.addMatch(Match(anyOf: p))))
            }
        }
    }
    
    func match(
        _ p: Predicate,
        @TAMBuilder<S> rows: () -> [TAM<S>]
    ) -> [TAM<S>] {
        match(anyOf: [p], rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        @TAMBuilder<S> rows: () -> [TAM<S>]
    ) -> [TAM<S>] {
        match(anyOf: [p] + ps, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        @TAMBuilder<S> rows: () -> [TAM<S>]
    ) -> [TAM<S>] {
        rows().reduce(into: [TAM]()) {
            $0.append($1.addMatch(Match(anyOf: p)))
        }
    }
    
    func match(
        _ p: Predicate,
        @WAMBuilder<E> rows: () -> [WAM<E>]
    ) -> [WAM<E>] {
        match(anyOf: [p], rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        @WAMBuilder<E> rows: () -> [WAM<E>]
    ) -> [WAM<E>] {
        match(anyOf: [p] + ps, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        @WAMBuilder<E> rows: () -> [WAM<E>]
    ) -> [WAM<E>] {
        rows().reduce(into: [WAM]()) {
            $0.append($1.addMatch(Match(anyOf: p)))
        }
    }
    
    func when(
        _ e: Event...,
        file: String = #file,
        line: Int = #line
    ) -> WAM<E> {
        when(e, file: file, line: line)
    }
    
    func when(
        _ e: [Event],
        file: String = #file,
        line: Int = #line
    ) -> WAM<E> {
        WAM(events: e,
            actions: [],
            match: .none,
            file: file,
            line: line)
    }
    
    func when(
        _ e: Event...,
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAM<S>]
    ) -> [WTAMRow<S, E>] {
        when(e, file: file, line: line, rows: rows)
    }
    
    func when(
        _ e: [Event],
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAM<S>]
    ) -> [WTAMRow<S, E>] {
        rows().reduce(into: [WTAMRow]()) {
            $0.append(WTAMRow(wtam: WTAM(events: e,
                                         tam: $1,
                                         file: file,
                                         line: line)))
        }
    }
    
    func then(_ state: S) -> TAM<S> {
        TAM(state: state)
    }
    
    func then(
        _ s: State,
        @WAMBuilder<E> rows: () -> [WAM<E>]
    ) -> [WTAMRow<S, E>] {
        rows().reduce(into: [WTAMRow]()) {
            $0.append(WTAMRow(wtam: WTAM(state: s, wam: $1)))
        }
    }
}

extension WTAM {
    init(state: S, wam: WAM<E>) {
        self.init(events: wam.events,
                  state: state,
                  actions: wam.actions,
                  match: wam.match,
                  file: wam.file,
                  line: wam.line)
    }
    
    init(events: [E], tam: TAM<S>, file: String, line: Int) {
        self.init(events: events,
                  state: tam.state,
                  actions: tam.actions,
                  match: tam.match,
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

extension TAM {
    func addMatch(_ m: Match) -> Self {
        .init(state: state,
              actions: actions,
              match: match + m)
    }
}

extension WAM {
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
        Set(
            uniqueTypes
                .allPossibleCases
                .erase()
                .uniquePermutations(ofCount: uniqueTypes.count)
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
    
    func allMatches(_ ps: PredicateSets = []) -> PredicateSets {
        let anyAndAll = anyOf.reduce(into: emptySets()) {
            $0.insert(Set(allOf) + [$1])
        }.removeEmpties ??? [allOf].asSets
        
        return ps.reduce(into: emptySets()) { result, p in
            anyAndAll.forEach { result.insert(p + $0) }
        }.removeEmpties ??? ps ??? anyAndAll
    }
}

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}

extension Set {
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
}
