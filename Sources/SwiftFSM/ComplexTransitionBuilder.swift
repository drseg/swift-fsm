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
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        match(anyOf: [p], file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        match(anyOf: [p] + ps, file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        concatenateWTAMRows(rows(), file: file, line: line) {
            $0.addMatch(Match(anyOf: p))
        }
    }
    
    func match(
        _ p: Predicate,
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAMRow<S>]
    ) -> [TAMRow<S>] {
        match(anyOf: [p], file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAMRow<S>]
    ) -> [TAMRow<S>] {
        match(anyOf: [p] + ps, file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAMRow<S>]
    ) -> [TAMRow<S>] {
        rows().reduce(into: [TAMRow]()) {
            if let tam = $1.tam {
                $0.append(
                    TAMRow(tam: tam.addMatch(Match(anyOf: p)))
                )
            }
        } ??? [.error(file, line)]
    }
    
    func match(
        _ p: Predicate,
        file: String = #file,
        line: Int = #line,
        @WAMBuilder<E> rows: () -> [WAMRow<E>]
    ) -> [WAMRow<E>] {
        match(anyOf: [p], file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: Predicate,
        _ ps: Predicate...,
        file: String = #file,
        line: Int = #line,
        @WAMBuilder<E> rows: () -> [WAMRow<E>]
    ) -> [WAMRow<E>] {
        match(anyOf: [p] + ps, file: file, line: line, rows: rows)
    }
    
    func match(
        anyOf p: [Predicate],
        file: String = #file,
        line: Int = #line,
        @WAMBuilder<E> rows: () -> [WAMRow<E>]
    ) -> [WAMRow<E>] {
        rows().reduce(into: [WAMRow]()) {
            if let wam = $1.wam {
                $0.append(
                    WAMRow(wam: wam.addMatch(Match(anyOf: p)))
                )
            }
        } ??? [.error(file, line)]
    }
    
    func when(
        _ e: Event...,
        file: String = #file,
        line: Int = #line
    ) -> WAMRow<E> {
        when(e, file: file, line: line)
    }
    
    func when(
        _ e: [Event],
        file: String = #file,
        line: Int = #line
    ) -> WAMRow<E> {
        WAMRow(wam: WAM(events: e,
                        actions: [],
                        match: .none,
                        file: file,
                        line: line))
    }
    
    func when(
        _ e: Event...,
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAMRow<S>]
    ) -> [WTAMRow<S, E>] {
        when(e, file: file, line: line, rows: rows)
    }
    
    func when(
        _ e: [Event],
        file: String = #file,
        line: Int = #line,
        @TAMBuilder<S> rows: () -> [TAMRow<S>]
    ) -> [WTAMRow<S, E>] {
        concatenateRows(rows(), file: file, line: line) {
            guard let tam = $0.tam else { return nil }
            return WTAMRow(wtam: WTAM(events: e,
                                      tam: tam,
                                      file: file,
                                      line: line))
        }
    }
    
    func then(_ state: S) -> TAMRow<S> {
        TAMRow(tam: TAM(state: state))
    }
    
    func then(
        _ s: State,
        file: String = #file,
        line: Int = #line,
        @WAMBuilder<E> rows: () -> [WAMRow<E>]
    ) -> [WTAMRow<S, E>] {
        rows().reduce(into: [WTAMRow]()) {
            if let wam = $1.wam {
                $0.append(WTAMRow(wtam: WTAM(state: s, wam: wam)))
            }
        } ??? [.error(file, line)]
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

extension Collection where Element == any PredicateProtocol {
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
