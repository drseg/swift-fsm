//
//  SemanticValidationNode.swift
//  
//  Created by Daniel Segall on 18/03/2023.
//

import Foundation

protocol SVNKey {
    init(_ input: SemanticValidationNode.Input)
}

protocol SVNError: LocalizedError {}
extension SVNError {
    func description<K: Hashable, V: Collection>(
        _ header: String,
        _ dict: [K: V],
        @StringBuilder _ block: (V.Element) -> [String]
    ) -> String {
        String {
            header
            for v in dict.values {
                ""
                for (i, element) in v.enumerated() {
                    block(element)
                    if i < v.count - 1 {
                        ""
                    }
                }
            }
        }
    }
}


class SemanticValidationNode: Node {
    struct DuplicatesError: SVNError {
        let duplicates: DuplicatesDictionary
        
        var errorDescription: String? {
            description("The FSM table contains the following duplicates:", duplicates) { d in
                d.state.defineDescription
                d.match.errorDescription
                d.event.whenDescription
                d.nextState.thenDescription
            }
        }
    }
    
    struct ClashError: SVNError {
        let clashes: ClashesDictionary
        
        var errorDescription: String? {
            description("The FSM table contains the following logical clashes:", clashes) { c in
                c.state.defineDescription
                c.match.errorDescription
                c.event.whenDescription
            }
        }
    }
    
    struct DuplicatesKey: SVNKey, Hashable {
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
    
    struct ClashesKey: SVNKey, Hashable {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable
        
        init(_ input: Input) {
            state = input.state
            match = input.match
            event = input.event
        }
    }
    
    typealias DuplicatesDictionary = [DuplicatesKey: [Input]]
    typealias ClashesDictionary = [ClashesKey: [Input]]
    
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
    
    func combinedWithRest(_ rest: [ActionsResolvingNode.Output]) -> [Output] {
        var duplicates = DuplicatesDictionary()
        var clashes = ClashesDictionary()
    
        let output = rest.reduce(into: [Output]()) { result, row in
            func isDuplicate(_ lhs: Input) -> Bool {
                DuplicatesKey(lhs) == DuplicatesKey(row)
            }
            
            func isClash(_ lhs: Input) -> Bool {
                ClashesKey(lhs) == ClashesKey(row)
            }
            
            func add<T: SVNKey>(_ existing: Output, row: Output, to dict: inout [T: [Input]]) {
                let key = T(row)
                dict[key] = (dict[key] ?? [existing]) + [row]
            }
            
            if let dupe = result.first(where: isDuplicate) {
                add(dupe, row: row, to: &duplicates)
            }
            
            else if let clash = result.first(where: isClash) {
                add(clash, row: row, to: &clashes)
            }
            
            result.append(row)
        }
        
        if !duplicates.isEmpty {
            errors.append(DuplicatesError(duplicates: duplicates))
        }
        
        if !clashes.isEmpty {
            errors.append(ClashError(clashes: clashes))
        }
        
        return errors.isEmpty ? output : []
    }
    
    func validate() -> [Error] {
        errors
    }
}
