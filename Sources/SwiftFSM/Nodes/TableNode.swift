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
    
    struct RankedOutput {
        let state: AnyTraceable,
            predicateResult: PredicateResult,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action]
        
        var toOutput: Output {
            (state, predicateResult.predicates, event, nextState, actions)
        }
    }
    
    struct ImplicitClashesError: Error {
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
        var clashes = ImplicitClashesDictionary()
        
        let result = rest.reduce(into: [RankedOutput]()) { result, input in
            func appendInput(_ predicateResult: PredicateResult = PredicateResult()) {
                let ro = RankedOutput(state: input.state,
                                      predicateResult: predicateResult,
                                      event: input.event,
                                      nextState: input.nextState,
                                      actions: input.actions)
                
                func isRankedClash(_ lhs: RankedOutput) -> Bool {
                    isClash(lhs) && lhs.predicateResult.rank != ro.predicateResult.rank
                }
                
                func isClash(_ lhs: RankedOutput) -> Bool {
                    ImplicitClashesKey(lhs.toOutput) == ImplicitClashesKey(ro.toOutput)
                }
                
                func highestRank(_ lhs: RankedOutput, _ rhs: RankedOutput) -> RankedOutput {
                    lhs.predicateResult.rank > rhs.predicateResult.rank ? lhs : rhs
                }
                
                if let i = result.firstIndex(where: isRankedClash) {
                    result[i] = highestRank(result[i], ro)
                }
                
                else {
                    if let clash = result.first(where: isClash) {
                        let key = ImplicitClashesKey(ro.toOutput)
                        clashes[key] = (clashes[key] ?? [clash.toOutput]) + [ro.toOutput]
                    }
                    result.append(ro)
                }
            }
            
            let allPredicateCombinations = input.match.allPredicateCombinations(rest.allCases)
            guard !allPredicateCombinations.isEmpty else {
                appendInput(); return
            }
            
            allPredicateCombinations.forEach(appendInput)
        }
        
        if !clashes.isEmpty {
            errors.append(ImplicitClashesError(clashes: clashes))
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

extension [SemanticValidationNode.Output] {
    var allCases: PredicateSets {
        let matches = map(\.match)
        let anys = matches.map(\.matchAny)
        let alls = matches.map(\.matchAll)
        return (alls + anys).flattened.combinationsOfAllCases
    }
}

