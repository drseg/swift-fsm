//
//  Match.swift
//  
//  Created by Daniel Segall on 22/02/2023.
//

import Foundation

class Match {
    typealias MatchResult = Result<Match, MatchError>
    typealias AnyH = AnyHashable
    
    static func + (lhs: Match, rhs: Match) -> Match {
        .init(any: lhs.matchAny + rhs.matchAny,
              all: lhs.matchAll + rhs.matchAll,
              file: lhs.file,
              line: lhs.line)
    }
    
    let matchAny: [AnyH]
    let matchAll: [AnyH]
    
    let file: String
    let line: Int
    
    private var next: Match? = nil
    
    convenience init(_ p: AnyH..., file: String = #file, line: Int = #line) {
        self.init(any: [], all: p, file: file, line: line)
    }
    
    convenience init(
        any: AnyH,
        _ any2: AnyH,
        _ anyRest: AnyH...,
        all: AnyH,
        _ all2: AnyH,
        _ allRest: AnyH...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any, any2] + anyRest, all: [all, all2] + allRest, file: file, line: line)
    }
    
    convenience init(
        any: AnyH,
        _ any2: AnyH,
        _ anyRest: AnyH...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [any, any2] + anyRest, all: [], file: file, line: line)
    }
    
    convenience init(
        all: AnyH,
        _ all2: AnyH,
        _ allRest: AnyH...,
        file: String = #file,
        line: Int = #line
    ) {
        self.init(any: [], all: [all, all2] + allRest, file: file, line: line)
    }
    
    init(any: [AnyH], all: [AnyH], file: String = #file, line: Int = #line) {
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
        guard let next else { return self.validate() }
        
        let firstResult = self.validate()
        let restResult = next.finalise()
        
        switch (firstResult, restResult) {
        case (.success, .success(let rest)):
            let combinedResult = (self + rest).validate()
            
            if case .failure = combinedResult {
                return combinedResult.appending(file: rest.file, line: rest.line)
            }
            return combinedResult
            
        case (.failure, .failure(let e)):
            return firstResult.appending(files: e.files, lines: e.lines)
            
        case (.success, .failure):
            return restResult
            
        case (.failure, .success):
            return firstResult
        }
    }
    
    private func validate() -> MatchResult {
        func failure<C: Collection>(
            predicates: C,
            type: MatchError.Type
        ) -> MatchResult where C.Element == AnyH {
            .failure(type.init(message: predicates.formattedDescription(),
                               files: [file],
                               lines: [line]))
        }
        
        guard matchAll.elementsAreUniquelyTyped else {
            return failure(predicates: matchAll,
                           type: DuplicateTypes.self)
        }
        
        guard matchAny.elementsAreUnique else {
            return failure(predicates: matchAny,
                           type: DuplicateValues.self)
        }
                
        let intersection = matchAll.filter { matchAny.contains($0) }
        guard intersection.isEmpty else {
            return failure(predicates: intersection,
                           type: DuplicateValues.self)
        }
        
        return .success(self)
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
    func appending(file: String, line: Int) -> Self {
        appending(files: [file], lines: [line])
    }
    
    func appending(files: [String], lines: [Int]) -> Self {
        if case .failure(let error) = self {
            return .failure(error.append(files: files, lines: lines))
        }
        
        return self
    }
}

extension AnyHashable {
    var type: String {
        String(describing: Swift.type(of: base))
    }
}

extension Collection where Element == AnyHashable {
    func formattedDescription() -> String {
        map(\.description)
            .sorted()
            .joined(separator: ", ")
    }
    
    var elementsAreUnique: Bool {
        Set(self).count == count
    }
    
    var elementsAreUniquelyTyped: Bool {
        uniqueElementTypes.count == count
    }
    
    var uniqueElementTypes: Set<String> {
        Set(map(\.type))
    }
}
