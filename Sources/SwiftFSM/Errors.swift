//
//  NodeErrors.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

#warning("why does this take files and lines and not Matches?")
class MatchError: LocalizedError {
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

class DuplicateMatchTypes: MatchError {}

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

struct CompoundError: LocalizedError, CustomStringConvertible {
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
