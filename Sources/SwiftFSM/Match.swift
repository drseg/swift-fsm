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
        lhs.add(any: rhs.matchAny, all: rhs.matchAll)
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
        self.init(any: [],
                  all: p,
                  file: file,
                  line: line)
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
        guard let next else {
            return validate(self)
        }
        
        let thisResult = validate(self)
        let nextResult = next.finalise()
        
        switch (thisResult, nextResult) {
        case (.success, .success(let next)):
            let additionResult = validate(self + next)
            
            if case .failure = additionResult {
                return additionResult.append(files: [next.file],
                                             lines: [next.line])
            }
            return additionResult
            
        case (.failure, .failure(let f)):
            return thisResult.append(files: f.files, lines: f.lines)
            
        case (.success, .failure):
            return nextResult
            
        case (.failure, .success):
            return thisResult
        }
    }
    
    private func validate(_ m: Match) -> MatchResult {
        guard m.matchAll.elementsAreUniquelyTyped else {
            let message = m.matchAll.formattedDescription()
            return .failure(DuplicateTypes(message: message,
                                           files: [file],
                                           lines: [line]))
        }
        
        guard m.matchAny.elementsAreUnique else {
            let message = m.matchAny.formattedDescription()
            return .failure(DuplicateValues(message: message,
                                            files: [file],
                                            lines: [line]))
        }
        
        let intersection = Set(m.matchAll).intersection(Set(m.matchAny))
        guard intersection.isEmpty else {
            let message = intersection.formattedDescription()
            return .failure(DuplicateValues(message: message,
                                            files: [file],
                                            lines: [line]))
        }
        
        return .success(m)
    }

    private func add(any: [AnyPredicate], all: [AnyPredicate]) -> Match {
        .init(any: matchAny + any,
              all: matchAll + all)
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
    func append(files: [String], lines: [Int]) -> Self {
        if case .failure(let failure) = self {
            return .failure(failure.append(files: files, lines: lines))
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
