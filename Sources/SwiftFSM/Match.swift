//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

class Match {
    typealias Result = Swift.Result<Match, MatchError>
    typealias AnyP = any Predicate
    
    static func + (lhs: Match, rhs: Match) -> Match {
        .init(any: lhs.matchAny + rhs.matchAny,
              all: lhs.matchAll + rhs.matchAll,
              file: lhs.file,
              line: lhs.line)
    }
    
    let matchAny: [AnyPredicate]
    let matchAll: [AnyPredicate]
    
    let file: String
    let line: Int
    
    private var next: Match? = nil
    
    convenience init(_ p: AnyP..., file: String = #file, line: Int = #line) {
        self.init(any: [], all: p, file: file, line: line)
    }
    
    convenience init(
        any: AnyP,
        _ any2: AnyP,
        _ anyRest: AnyP...,
        all: AnyP,
        _ all2: AnyP,
        _ allRest: AnyP...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any, any2] + anyRest, all: [all, all2] + allRest, file: file, line: line)
    }
    
    convenience init(
        any: AnyP,
        _ any2: AnyP,
        _ anyRest: AnyP...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any, any2] + anyRest, all: [], file: file, line: line)
    }
    
    convenience init(
        all: AnyP,
        _ all2: AnyP,
        _ allRest: AnyP...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [], all: [all, all2] + allRest, file: file, line: line)
    }
    
    convenience init(any: [AnyP], all: [AnyP], file: String = #file, line: Int = #line) {
        self.init(any: any.erase(), all: all.erase(), file: file, line: line)
    }
    
    init(any: [AnyPredicate], all: [AnyPredicate], file: String = #file, line: Int = #line) {
        self.matchAny = any
        self.matchAll = all
        self.file = file
        self.line = line
    }
    
    func prepend(_ m: Match) -> Match {
        m.next = self
        return m
    }
    
    func finalise() -> Result {
        guard let next else { return self.validate() }
        
        let firstResult = self.validate()
        let restResult = next.finalise()
        
        switch (firstResult, restResult) {
        case (.success, .success(let rest)):
            return (self + rest).validate().appending(file: rest.file, line: rest.line)
            
        case (.failure, .failure(let e)):
            return firstResult.appending(files: e.files, lines: e.lines)
            
        case (.success, .failure):
            return restResult
            
        case (.failure, .success):
            return firstResult
        }
    }
    
    private func validate() -> Result {
        func failure<C: Collection>(
            predicates: C,
            type: MatchError.Type
        ) -> Result where C.Element == AnyPredicate {
            .failure(type.init(message: predicates.formattedDescription(),
                               files: [file],
                               lines: [line]))
        }
        
        guard matchAll.elementsAreUniquelyTyped else {
            return failure(predicates: matchAll, type: DuplicateTypes.self)
        }
        
        guard matchAny.elementsAreUnique else {
            return failure(predicates: matchAny, type: DuplicateValues.self)
        }
                
        let intersection = matchAll.filter { matchAny.contains($0) }
        guard intersection.isEmpty else {
            return failure(predicates: intersection, type: DuplicateValues.self)
        }
        
        return .success(self)
    }
    
    
    func allPredicateCombinations(_ ps: PredicateSets) -> PredicateSets {
        var emptySets: PredicateSets { Set(arrayLiteral: Set([AnyPredicate]())) }
        
        let anyAndAll = matchAny.reduce(into: emptySets) {
            $0.insert(Set(matchAll) + [$1])
        }.removingEmpties ??? [matchAll].asSets
        
        let includedTypes = (matchAny + matchAll).uniqueElementTypes
        return ps.reduce(into: emptySets) { result, p in
            var filtered = p
            while let existing = filtered.first(where: { includedTypes.contains($0.type) }) {
                filtered.remove(existing)
            }
            anyAndAll.forEach { result.insert(filtered + $0) }
        }.removingEmpties ??? ps ??? anyAndAll
    }
}

class MatchError: Error {
    let message: String
    let files: [String]
    let lines: [Int]
    
    required init(message: String, files: [String], lines: [Int]) {
        self.message = message
        self.files = files
        self.lines = lines
    }
    
    func append(files: [String], lines: [Int]) -> Self {
        .init(message: message,
              files: self.files + files,
              lines: self.lines + lines)
    }
}

class DuplicateTypes: MatchError {}
class DuplicateValues: MatchError {}

extension Match.Result {
    func appending(file: String, line: Int) -> Self {
        appending(files: [file], lines: [line])
    }
    
    func appending(files: [String], lines: [Int]) -> Self {
        mapError { $0.append(files: files, lines: lines) }
    }
}

extension Collection where Element == AnyPredicate {
    func formattedDescription() -> String {
        map(\.description)
            .sorted()
            .joined(separator: ", ")
    }
}

extension Collection where Element: Collection & Hashable, Element.Element: Hashable {
    var asSets: Set<Set<Element.Element>> {
        Set(map(Set.init)).removingEmpties
    }
    
    var removingEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}

extension Set {
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
}
