//
//  SemanticValidationNode.swift
//  
//  Created by Daniel Segall on 18/03/2023.
//

import Foundation

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
    
    struct DuplicatesKey: Hashable {
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
    
    struct ClashesKey: Hashable {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
        }
    }
    
    struct MatchClashesKey: Hashable {
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
            func areDuplicates(_ lhs: Input) -> Bool {
                DuplicatesKey(lhs) == DuplicatesKey(row)
            }
            
            func areClashes(_ lhs: Input) -> Bool {
                ClashesKey(lhs) == ClashesKey(row)
            }
            
            func areMatchClashes(_ lhs: Input) -> Bool {
                MatchClashesKey(lhs) == MatchClashesKey(row)
            }
            
            if let existing = checked.first(where: areDuplicates) {
                let key = DuplicatesKey(row)
                duplicates[key] = (duplicates[key] ?? [existing]) + [row]
            }
            
            else if let existing = checked.first(where: areClashes) {
                let key = ClashesKey(row)
                clashes[key] = (clashes[key] ?? [existing]) + [row]
            }
            
            else if let existing = checked.first(where: areMatchClashes) {
                let key = MatchClashesKey(row)
                matchClashes[key] = (matchClashes[key] ?? [existing]) + [row]
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
