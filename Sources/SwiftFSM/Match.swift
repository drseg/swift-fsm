//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

class Match {
    typealias PredicateSets = Set<PredicateSet>
    typealias PredicateSet = Set<AnyPredicate>
    typealias MatchResult = Result<Match, MatchError>
    
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
    
    convenience init(
        _ p: any PredicateProtocol...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [], all: p, file: file, line: line)
    }
    
    convenience init(
        any: any PredicateProtocol,
        _ any2: any PredicateProtocol,
        _ anyRest: any PredicateProtocol...,
        all: any PredicateProtocol,
        _ all2: any PredicateProtocol,
        _ allRest: any PredicateProtocol...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any.erase(), any2.erase()] + anyRest.erase(),
                  all: [all.erase(), all2.erase()] + allRest.erase(),
                  file: file,
                  line: line)
    }
    
    convenience init(
        any: any PredicateProtocol,
        _ any2: any PredicateProtocol,
        _ anyRest: any PredicateProtocol...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any.erase(), any2.erase()] + anyRest.erase(),
                  all: [],
                  file: file,
                  line: line)
    }
    
    convenience init(
        all: any PredicateProtocol,
        _ all2: any PredicateProtocol,
        _ allRest: any PredicateProtocol...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [],
                  all: [all.erase(), all2.erase()] + allRest.erase(),
                  file: file,
                  line: line)
    }
        
    convenience init(
        any: [any PredicateProtocol],
        all: [any PredicateProtocol],
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: any.erase(),
                  all: all.erase(),
                  file: file,
                  line: line)
    }
    
    init(
        any: [AnyPredicate],
        all: [AnyPredicate],
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
    
    func finalise() -> MatchResult {
        guard let next else { return validate(self) }
        
        let firstResult = validate(self)
        let restResult = next.finalise()
        
        switch (firstResult, restResult) {
        case (.success, .success(let rest)):
            let combinedResult = validate(self + rest)
            
            if case .failure = combinedResult {
                return combinedResult.append(file: rest.file, line: rest.line)
            }
            return combinedResult
            
        case (.failure, .failure(let e)):
            return firstResult.append(files: e.files, lines: e.lines)
            
        case (.success, .failure):
            return restResult
            
        case (.failure, .success):
            return firstResult
        }
    }
    
    private func validate(_ m: Match) -> MatchResult {
        func failure<C: Collection>(
            predicates: C,
            type: MatchError.Type
        ) -> MatchResult where C.Element == AnyPredicate {
            .failure(type.init(message: predicates.formattedDescription(),
                               files: [file],
                               lines: [line]))
        }
        
        guard m.matchAll.elementsAreUniquelyTyped else {
            return failure(predicates: m.matchAll,
                           type: DuplicateTypes.self)
        }
        
        guard m.matchAny.elementsAreUnique else {
            return failure(predicates: m.matchAny,
                           type: DuplicateValues.self)
        }
                
        let intersection = matchAll.filter { matchAny.contains($0) }
        guard intersection.isEmpty else {
            return failure(predicates: intersection,
                           type: DuplicateValues.self)
        }
        
        return .success(m)
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
        Self.init(message: message,
                  files: self.files + files,
                  lines: self.lines + lines)
    }
}

class DuplicateTypes: MatchError {}
class DuplicateValues: MatchError {}

extension Result<Match, MatchError> {
    func append(file: String, line: Int) -> Self {
        append(files: [file], lines: [line])
    }
    
    func append(files: [String], lines: [Int]) -> Self {
        if case .failure(let error) = self {
            return .failure(error.append(files: files, lines: lines))
        }
        
        return self
    }
}

extension Set {
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }
}

extension Collection {
    func formattedDescription() -> String where Element == AnyPredicate {
        map(\.description)
            .sorted()
            .joined(separator: ", ")
    }
}

extension Collection
where Element: Collection & Hashable, Element.Element: Hashable
{
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
