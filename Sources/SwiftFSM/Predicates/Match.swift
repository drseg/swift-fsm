//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

class Match {
    typealias Result = Swift.Result<Match, MatchError>
    typealias AnyPP = any Predicate
    
    static func + (lhs: Match, rhs: Match) -> Match {
        .init(any: lhs.matchAny + rhs.matchAny,
              all: lhs.matchAll + rhs.matchAll,
              file: lhs.file,
              line: lhs.line)
    }
    
    let matchAny: [[AnyPredicate]]
    let matchAll: [AnyPredicate]
    
    let file: String
    let line: Int
    
    private var next: Match? = nil
    
    convenience init(any: AnyPP..., all: AnyPP..., file: String = #file, line: Int = #line) {
        self.init(any: any.erased(), all: all.erased(), file: file, line: line)
    }
    
    convenience init(any: [[AnyPP]], all: AnyPP..., file: String = #file, line: Int = #line) {
        self.init(any: any.map { $0.erased() }, all: all.erased(), file: file, line: line)
    }
    
    init(any: [AnyPredicate], all: [AnyPredicate], file: String = #file, line: Int = #line) {
        self.matchAny = [any].filter { !$0.isEmpty }
        self.matchAll = all
        self.file = file
        self.line = line
    }
    
    init(any: [[AnyPredicate]], all: [AnyPredicate], file: String = #file, line: Int = #line) {
        self.matchAny = any
        self.matchAll = all
        self.file = file
        self.line = line
    }
    
    func prepend(_ m: Match) -> Match {
        m.next = self
        return m
    }
    
    func finalised() -> Result {
        guard let next else { return self.validate() }
        
        let firstResult = self.validate()
        let restResult = next.finalised()
        
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
            duplicates: C,
            type: MatchError.Type
        ) -> Result where C.Element == AnyPredicate {
            .failure(
                type.init(
                    message: duplicates.formattedDescription(),
                    files: [file],
                    lines: [line]
                )
            )
        }
        
        guard matchAll.elementsAreUniquelyTyped else {
            return failure(duplicates: matchAll, type: DuplicateMatchTypes.self)
        }
        
        guard matchAny.flattened.elementsAreUnique else {
            return failure(duplicates: matchAny.flattened, type: DuplicateMatchValues.self)
        }
                
        let duplicates = matchAll.filter { matchAny.flattened.contains($0) }
        guard duplicates.isEmpty else {
            return failure(duplicates: duplicates, type: DuplicateMatchValues.self)
        }
        
        return .success(self)
    }
    
    func allPredicateCombinations(_ ps: PredicateSets) -> Set<PredicateResult> {
        func makeResult(_ p: PredicateSet) -> PredicateResult {
            .init(predicates: p, rank: anyAndAll.first?.count ?? 0)
        }
        
        let anyAndAll = combineAnyAndAll()
        return ps.reduce(into: Set<PredicateResult>()) { result, p in
            let filtered = removeDuplicates(p)
            if anyAndAll.isEmpty {
                result.insert(makeResult(filtered))
            } else {
                anyAndAll.forEach {
                    result.insert(makeResult(filtered.union($0)))
                }
            }
        }.removingEmpties ??? Set(anyAndAll.map(makeResult))
    }
    
    func combineAnyAndAll() -> PredicateSets {
        matchAny.combinations().reduce(into: [[AnyPredicate]]()) {
           $0.append(matchAll + $1)
       }.asSets ??? [matchAll].asSets
    }
    
    func removeDuplicates(_ p: PredicateSet) -> PredicateSet {
        var filtered = p
        let includedTypes = (matchAny.flattened + matchAll).uniqueElementTypes
        while let existing = filtered.first(where: { includedTypes.contains($0.type) }) {
            filtered.remove(existing)
        }
        return filtered
    }
}

extension Match: Hashable {
    public static func == (lhs: Match, rhs: Match) -> Bool {
        func sort(_ any: [[AnyPredicate]]) -> [[AnyPredicate]] {
            any.map { $0.sorted(by: sort) }
        }
        
        func sort(_ p1: AnyPredicate, _ p2: AnyPredicate) -> Bool {
            String(describing: p1) > String(describing: p2)
        }
        
        let lhsAny = sort(lhs.matchAny)
        let rhsAny = sort(rhs.matchAny)
        
        return lhs.matchAny.count == rhs.matchAny.count &&
        lhs.matchAll.count == rhs.matchAll.count &&
        lhsAny.allSatisfy({ rhsAny.contains($0) }) &&
        lhs.matchAll.allSatisfy({ rhs.matchAll.contains($0) })
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(matchAny)
        hasher.combine(matchAll)
    }
}

struct PredicateResult: Hashable {
    let predicates: PredicateSet
    let rank: Int
}

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
}

protocol PossiblyEmpty {
    var isEmpty: Bool { get }
}

extension Set: PossiblyEmpty { }
extension PredicateResult: PossiblyEmpty {
    var isEmpty: Bool { predicates.isEmpty }
}

extension Collection where Element: PossiblyEmpty & Hashable {
    var removingEmpties: Set<Element> {
        Set(filter { !$0.isEmpty })
    }
}
