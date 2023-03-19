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
    
    struct _Output {
        let state: AnyTraceable,
            predicateResult: PredicateResult,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action]
        
        var toOutput: Output {
            (state, predicateResult.predicates, event, nextState, actions)
        }
    }
    
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
        
        var clashes = ImplicitClashesDictionary()
        
        let result = rest.reduce(into: [_Output]()) { result, input in
            func appendInput(_ predicateResult: PredicateResult = PredicateResult()) {
                let _output = _Output(state: input.state,
                                      predicateResult: predicateResult,
                                      event: input.event,
                                      nextState: input.nextState,
                                      actions: input.actions)
                
                func isRankedClash(_ lhs: _Output) -> Bool {
                    isClash(lhs) && lhs.predicateResult.rank != _output.predicateResult.rank
                }
                
                func isClash(_ lhs: _Output) -> Bool {
                    ImplicitClashesKey(lhs.toOutput) == ImplicitClashesKey(_output.toOutput)
                }
                
                func highestRank(_ lhs: _Output, _ rhs: _Output) -> _Output {
                    lhs.predicateResult.rank > rhs.predicateResult.rank ? lhs : rhs
                }
                
                if let rankedClashIndex = result.firstIndex(where: isRankedClash) {
                    result[rankedClashIndex] = highestRank(result[rankedClashIndex], _output)
                }
                
                else {
                    if let clash = result.first(where: isClash) {
                        let key = ImplicitClashesKey(_output.toOutput)
                        clashes[key] = (clashes[key] ?? [clash.toOutput]) + [_output.toOutput]
                    }
                    result.append(_output)
                }
            }
            
            let allPredicateCombinations = input.match.allPredicateCombinations(allCases)
            guard !allPredicateCombinations.isEmpty else {
                appendInput(); return
            }
            
            allPredicateCombinations.forEach {
                appendInput($0)
            }
        }
        
        if !clashes.isEmpty {
            errors.append(ImplicitClashError(clashes: clashes))
        }
        
        return result.map(\.toOutput)
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

