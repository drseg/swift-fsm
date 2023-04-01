//
//  NodeErrors.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

struct SwiftFSMError: LocalizedError, CustomStringConvertible {
    let errors: [Error]
    var description: String { localizedDescription }
    
    var errorDescription: String? {
        String {
            "- SwiftFSM Errors -"
            ""
            "\(errors.count) errors were found:"
            ""
            errors.map { $0.localizedDescription }.joined(separator: "\n")
            ""
            "- End -"
        }
    }
}

class MatchError: Error {
    let predicates: [AnyPredicate]
    let files: [String]
    let lines: [Int]
    
    required init<C: Collection>(
        predicates: C,
        files: [String],
        lines: [Int]
    ) where C.Element == AnyPredicate {
        self.predicates = Array(predicates)
        self.files = files
        self.lines = lines
    }
    
    func append(files: [String], lines: [Int]) -> Self {
        .init(predicates: predicates,
              files: self.files + files,
              lines: self.lines + lines)
    }
    
    func duplicates(_ keypath: KeyPath<AnyPredicate, String>) -> String {
        let strings = predicates.map { $0[keyPath: keypath] }
        return Set(strings.filter { s in strings.filter { s == $0 }.count > 1 })
            .map { [$0] }
            .reduce([], +)
            .sorted()
            .joined(separator: ", ")
    }
    
    func predicatesString(separator: String) -> String {
        predicates
            .map(\.description)
            .sorted()
            .joined(separator: separator)
    }
    
    var filesAndLines: String {
        zip(files, lines).reduce([]) {
            $0 + [("file \($1.0), line \($1.1)")]
        }.joined(separator: "\n")
    }
    
    var duplicatesList: String {
        String {
            if files.count > 1 {
                "This combination was formed by AND-ing 'matching' statements at:"
                filesAndLines
            } else {
                "This combination was found in a 'matching' statement at \(filesAndLines)"
            }
        }
    }
}

class DuplicateMatchTypes: MatchError, LocalizedError {
    var firstLine: String {
        String {
            let dupes = duplicates(\.type)
            let predicates = predicatesString(separator: " AND ")
            
            dupes.count > 1
            ? "'matching(\(predicates))' is ambiguous - types \(dupes) appear multiple times"
            : "'matching(\(predicates))' is ambiguous - type \(dupes) appears multiple times"
        }
    }
    
    var errorDescription: String? {
        String {
            firstLine
            duplicatesList
        }
    }
}

class DuplicateAnyValues: MatchError, LocalizedError {
    var errorDescription: String? {
        String {
            let dupes = duplicates(\.description)
            let predicates = predicatesString(separator: " OR ")
            "'matching(\(predicates))' contains multiple instances of \(dupes)"
            duplicatesList
        }
    }
}

class DuplicateAnyAllValues: MatchError, LocalizedError {
    var errorDescription: String? {
        String {
            let dupes = duplicates(\.description)
            if files.count > 1 {
                "When combined, 'matching' statements at:"
                filesAndLines
                "...contain multiple instances of \(dupes)"
            } else {
                "'matching' statement at \(filesAndLines) contains multiple instances of \(dupes)"
            }
        }
    }
}

struct EmptyBuilderError: LocalizedError, Equatable {
    let caller: String
    let file: String
    let line: Int
    
    init(caller: String = #function, file: String, line: Int) {
        self.caller = String(caller.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
    
    var errorDescription: String? {
        "Empty @resultBuilder block passed to '\(caller)' in \(file) at line \(line)"
    }
}

struct EmptyTableError: LocalizedError {
    var errorDescription: String? {
        "FSM tables must have at least one 'define' statement in them"
    }
}

struct NSObjectError: LocalizedError {
    var errorDescription: String? {
        String {
            "'State' and 'Event' types cannot:"
            ""
            "- Inherit from NSObject"
            "- Hold properties that inherit from NSObject'"
            ""
            "NSObject hashes by object id, leading to unintended FSM behaviour"
        }
    }
}

extension Match {
    var asArray: [Match] {
        [originalSelf?.removingNext ?? removingNext] + (next?.asArray ?? [])
    }
    
    var removingNext: Match {
        Match(any: matchAny, all: matchAll, file: file, line: line)
    }
    
    var errorDescription: String {
        let or = matchAny.reduce([String]()) { result, predicates in
            let firstPredicateString = predicates.first!.description
            
            return result + [predicates.dropFirst().reduce(firstPredicateString) {
                "(\($0) OR \($1))"
            }]
        }.joined(separator: " AND ")
        
        let and = matchAll.map(\.description).joined(separator: " AND ")
        
        var summary: String
        switch (matchAll.isEmpty, matchAny.isEmpty) {
        case (true, true): summary = "matching()"
        case (true, false): summary = "matching(\(or))"
        case (false, true): summary = "matching(\(and))"
        case (false, false): summary = "matching(\(or) AND \(and))"
        }
        
        let components = asArray
        guard components.count > 1 else {
            return summary + " @\(file): \(line)"
        }
        
        return String {
            summary
            "  formed by combining:"
            components.reduce([]) { $0 + ["    - " + $1.errorDescription] }.joined(separator: "\n")
        }
    }
}

extension AnyTraceable {
    var fileAndLine: String {
        "@\(file): \(line)"
    }
    
    var defineDescription: String {
        "define(\(base)) " + fileAndLine
    }
    
    var whenDescription: String {
        "when(\(base)) " + fileAndLine
    }
    
    var thenDescription: String {
        "then(\(base)) " + fileAndLine
    }
}

extension ResultBuilder {
    static func buildEither(first: [T]) -> [T] { first }
    static func buildEither(second: [T]) -> [T] { second }
    static func buildOptional(_ component: [T]?) -> [T] { component ?? [] }
    static func buildArray(_ components: [[T]]) -> [T] { components.flattened }
}

@resultBuilder struct StringBuilder: ResultBuilder { typealias T = String }
extension String {
    init(@StringBuilder _ b:  () -> [String]) {
        self.init(b().joined(separator: "\n"))
    }
}
