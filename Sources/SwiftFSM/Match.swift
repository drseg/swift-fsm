//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

class Match {
    typealias PredicateSets = Set<Set<AnyPredicate>>
    
    static func + (lhs: Match, rhs: Match) -> Match {
        lhs.add(any: rhs.matchAny, all: rhs.matchAll)
    }
    
    let matchAny: Set<AnyPredicate>
    let matchAll: Set<AnyPredicate>
    
    let file: String
    let line: Int
    
    private var next: Match? = nil
        
    init(
        any: [any PredicateProtocol] = [],
        all: [any PredicateProtocol] = [],
        file: String = #file,
        line: Int = #line
    ) {
        self.matchAll = Set(all.erase())
        self.matchAny = Set(any.erase())
        self.file = file
        self.line = line
    }
    
    init(
        any: Set<AnyPredicate>,
        all: Set<AnyPredicate>,
        file: String = #file,
        line: Int = #line
    ) {
        self.matchAny = any
        self.matchAll = all
        self.file = file
        self.line = line
    }
    
    func prepend(_ m: Match) -> Match {
        m.next = self
        return m
    }
    
    func finalise() -> Result<Match, MatchError> {
        guard let nextResult = next?.finalise() else {
            return validate(self)
        }
        
        if case .success(let success) = nextResult {
            return validate(self + success)
        }
        
        return nextResult
    }
    
    private func validate(_ m: Match) -> Result<Match, MatchError> {
        guard m.matchAll.elementsAreUniquelyTyped else {
            let message = m.matchAll.formattedDescription()
            return .failure(.duplicateTypes(message: message,
                                            file: file,
                                            line: line))
        }
        
        let intersection = m.matchAll.intersection(m.matchAny)
        guard intersection.isEmpty else {
            let message = intersection.formattedDescription()
            return .failure(.duplicateValues(message: message,
                                             file: file,
                                             line: line))
        }
        
        return .success(m)
    }

    private func add(any: Set<AnyPredicate>, all: Set<AnyPredicate>) -> Match {
        .init(any: matchAny.union(any),
              all: matchAll.union(all))
    }
    
    private func emptySets() -> PredicateSets {
        Set(arrayLiteral: Set([AnyPredicate]()))
    }
    
    func allMatches(_ ps: PredicateSets) -> PredicateSets {
        let anyAndAll = matchAny.reduce(into: emptySets()) {
            $0.insert(Set(matchAll) + [$1])
        }.removeEmpties ??? [matchAll].asSets
        
        return ps.reduce(into: emptySets()) { result, p in
            anyAndAll.forEach { result.insert(p + $0) }
        }.removeEmpties ??? ps ??? anyAndAll
    }
}

enum MatchError: Error, Equatable {
    case duplicateTypes(message: String, file: String, line: Int)
    case duplicateValues(message: String, file: String, line: Int)
    case unknownError
}

extension Match: Hashable {
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.matchAny == rhs.matchAny && lhs.matchAll == rhs.matchAll
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(matchAny)
        hasher.combine(matchAll)
    }
}

extension Set {
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
    
    func formattedDescription() -> String where Element == AnyPredicate {
        map(\.description)
            .sorted()
            .joined(separator: ", ")
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

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
