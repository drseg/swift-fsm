//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

struct Match {
    typealias PredicateSets = Set<Set<AnyPredicate>>
    
    let anyOf: Set<AnyPredicate>
    let allOf: Set<AnyPredicate>
    let file: String
    let line: Int
        
    init(
        anyOf: [any PredicateProtocol] = [],
        allOf: [any PredicateProtocol] = [],
        file: String = #file,
        line: Int = #line
    ) {
        self.allOf = Set(allOf.erase())
        self.anyOf = Set(anyOf.erase())
        self.file = file
        self.line = line
    }
    
    init(
        anyOf: Set<AnyPredicate>,
        allOf: Set<AnyPredicate>,
        file: String = #file,
        line: Int = #line
    ) {
        self.anyOf = anyOf
        self.allOf = allOf
        self.file = file
        self.line = line
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.add(any: rhs.anyOf, all: rhs.allOf)
    }

    func add(any: Set<AnyPredicate>, all: Set<AnyPredicate>) -> Self {
        .init(anyOf: anyOf.union(any), allOf: allOf.union(all))
    }
    
    private func emptySets() -> PredicateSets {
        Set(arrayLiteral: Set([AnyPredicate]()))
    }
    
    func allMatches(_ ps: PredicateSets) -> PredicateSets {
        let anyAndAll = anyOf.reduce(into: emptySets()) {
            $0.insert(Set(allOf) + [$1])
        }.removeEmpties ??? [allOf].asSets
        
        return ps.reduce(into: emptySets()) { result, p in
            anyAndAll.forEach { result.insert(p + $0) }
        }.removeEmpties ??? ps ??? anyAndAll
    }
}

extension Match: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.anyOf == rhs.anyOf && lhs.allOf == rhs.allOf
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(anyOf)
        hasher.combine(allOf)
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

extension Collection
where Element: Collection, Element: Hashable, Element.Element: Hashable {
    var asSets: Set<Set<Element.Element>> {
        Set(map(Set.init)).removeEmpties
    }
    
    var removeEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}
