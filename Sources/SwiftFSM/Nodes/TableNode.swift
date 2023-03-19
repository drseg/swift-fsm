//
//  TableNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

final class PreemptiveTableNode: Node {
    typealias Output = (state: AnyTraceable,
                        predicates: Set<AnyPredicate>,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    struct ImplicitClashError: Error {
        let clashes: ImplicitClashesDictionary
    }
    
    struct ImplicitClashesKey: Hashable {
        let state: AnyTraceable,
            predicates: Set<AnyPredicate>,
            event: AnyTraceable
        
        init(_ output: Output) {
            state = output.state
            predicates = output.predicates
            event = output.event
        }
    }
    
    typealias ImplicitClashesDictionary = [ImplicitClashesKey: [Output]]

    var rest: [any Node<Input>]
    var errors: [Error] = []
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Output] {
        let allCases = {
            let matches = rest.map(\.match)
            let anys = matches.map(\.matchAny)
            let alls = matches.map(\.matchAll)
            return (alls + anys).flattened.combinationsOfAllCases
        }()
        
        var checked = [Output]()
        var clashes = ImplicitClashesDictionary()
        
        let result = rest.reduce(into: [Output]()) { result, input in
            func appendInput(predicates: Set<AnyPredicate> = []) {
                let output = (state: input.state,
                              predicates: predicates,
                              event: input.event,
                              nextState: input.nextState,
                              actions: input.actions)
                
                func isClash(_ lhs: Output) -> Bool {
                    ImplicitClashesKey(lhs) == ImplicitClashesKey(output)
                }
                
                
                if let clash = checked.first(where: isClash) {
                    let key = ImplicitClashesKey(output)
                    clashes[key] = (clashes[key] ?? [clash]) + [output]
                }
                
                checked.append(output)
                result.append(output)
            }
            
            let allPredicateCombinations = input.match.allPredicateCombinations(allCases)
            guard !allPredicateCombinations.isEmpty else {
                appendInput(); return
            }
            
            allPredicateCombinations.forEach {
                appendInput(predicates: $0.predicates)
            }
        }
        
        if !clashes.isEmpty {
            errors.append(ImplicitClashError(clashes: clashes))
        }
        
        return result
    }
    
    func validate() -> [Error] {
        errors
    }
}

extension PredicateResult {
    init() {
        predicates = []
        rank = 0
    }
}

