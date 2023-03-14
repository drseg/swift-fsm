//
//  NodeErrors.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

#warning("why does this take files and lines and not Matches?")
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

struct LogicalClashError: Error {
    let clashes: TableNodeProtocol.ErrorDictionary
    
    init(_ clashes: TableNodeProtocol.ErrorDictionary) {
        self.clashes = clashes
    }
}

struct DuplicatesError: Error {
    let duplicates: TableNodeProtocol.ErrorDictionary
    
    init(_ duplicates: TableNodeProtocol.ErrorDictionary) {
        self.duplicates = duplicates
    }
}

struct EmptyBuilderError: Error, Equatable {
    let caller: String
    let file: String
    let line: Int
    
    init(caller: String = #function, file: String, line: Int) {
        self.caller = String(caller.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
}
