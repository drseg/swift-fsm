//
//  NodeErrors.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

struct SwiftFSMError: LocalizedError, CustomStringConvertible {
    let errors: [Error]
    
    var description: String {
        localizedDescription
    }
    
    var errorDescription: String? {
        String.build {
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

#warning("why does this take files and lines and not Matches?")
class MatchError: LocalizedError {
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
    
    var errorDescription: String? {
        ""
    }
}

class DuplicateMatchTypes: MatchError {
    var firstLine: String {
        let types = predicates.map(\.type)
        let dupes = Set(
            types.filter {
                type in types.filter { type == $0 }.count > 1
            }
        ).reduce(into: []) {
            $0.append($1)
        }.sorted().joined(separator: ", ")
        
        let predicates = predicates
            .map(\.description)
            .sorted()
            .joined(separator: " AND ")
        
        return dupes.count > 1
        ? "'matching(\(predicates))' is ambiguous - types \(dupes) appear multiple times"
        : "'matching(\(predicates))' is ambiguous - type \(dupes) appears multiple times"
    }
    
    override var errorDescription: String? {
        let filesAndLines = zip(files, lines).reduce(into: []) {
            $0.append("file \($1.0), line \($1.1)")
        }.joined(separator: "\n")
        
        print(filesAndLines)
        
        return files.count > 1
        ? String.build {
            firstLine
            "This combination was formed by AND-ing 'matching' statements at:"
            filesAndLines
        }
        : String.build {
            firstLine
            "This combination was found in a 'matching' statement at \(filesAndLines)"
        }
    }
}

class DuplicateMatchValues: MatchError {}

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
    
}

struct NSObjectError: LocalizedError {
    
}

struct TypeClashError: LocalizedError {
    
}

@resultBuilder struct StringBuilder: ResultBuilder { typealias T = String }
extension String {
    static func build(@StringBuilder _ b:  () -> [String]) -> String {
        b().joined(separator: "\n")
    }
}
