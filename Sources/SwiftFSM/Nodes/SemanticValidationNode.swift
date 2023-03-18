//
//  SemanticValidationNode.swift
//  
//  Created by Daniel Segall on 18/03/2023.
//

import Foundation

protocol Key {
    init(_ input: SemanticValidationNode.Input)
}

class SemanticValidationNode: Node {
    struct DuplicatesError: Error {
        let duplicates: DuplicatesDictionary
    }
    
    struct ClashError: Error {
        let clashes: ClashesDictionary
    }
    
    struct MatchClashError: Error {
        let clashes: MatchClashesDictionary
    }
    
    struct DuplicatesKey: Key, Hashable {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
            nextState = input.nextState
        }
    }
    
    struct ClashesKey: Key, Hashable {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
        }
    }
    
    struct MatchClashesKey: Key, Hashable {
        let state: AnyTraceable,
            event: AnyTraceable,
            nextState: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            event = input.event
            nextState = input.nextState
        }
    }
    
    typealias DuplicatesDictionary = [DuplicatesKey: [Input]]
    typealias ClashesDictionary = [ClashesKey: [Input]]
    typealias MatchClashesDictionary = [MatchClashesKey: [Input]]
    
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    var rest: [any Node<Input>]
    var errors: [Error] = []
    
    init(rest: [any Node<Input>]) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [TransitionNode.Output]) -> [Output] {
        var checked = [Output]()
        
        var duplicates = DuplicatesDictionary()
        var clashes = ClashesDictionary()
        var matchClashes = MatchClashesDictionary()
    
        let output = rest.reduce(into: [Output]()) { result, row in
            func isDuplicate(_ lhs: Input) -> Bool {
                DuplicatesKey(lhs) == DuplicatesKey(row)
            }
            
            func isClash(_ lhs: Input) -> Bool {
                ClashesKey(lhs) == ClashesKey(row)
            }
            
            func isMatchClash(_ lhs: Input) -> Bool {
                MatchClashesKey(lhs) == MatchClashesKey(row)
            }
            
            func add<T: Key>(_ existing: Output, row: Output, to dict: inout [T: [Input]]) {
                let key = T(row)
                dict[key] = (dict[key] ?? [existing]) + [row]
            }
            
            if let dupe = checked.first(where: isDuplicate) {
                add(dupe, row: row, to: &duplicates)
            }
            
            else if let clash = checked.first(where: isClash) {
                add(clash, row: row, to: &clashes)
            }
            
            else if let matchClash = checked.first(where: isMatchClash) {
                add(matchClash, row: row, to: &matchClashes)
            }
            
            checked.append(row)
            result.append(row)
        }
        
        if !duplicates.isEmpty {
            errors.append(DuplicatesError(duplicates: duplicates))
        }
        
        if !clashes.isEmpty {
            errors.append(ClashError(clashes: clashes))
        }
        
        if !matchClashes.isEmpty {
            errors.append(MatchClashError(clashes: matchClashes))
        }
        
        return output
    }
    
    func validate() -> [Error] {
        errors
    }
}
