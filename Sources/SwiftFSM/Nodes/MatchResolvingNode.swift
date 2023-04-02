//
//  MatchResolvingNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

final class MatchResolvingNode: Node {
    typealias Output = (state: AnyTraceable,
                        predicates: PredicateSet,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    typealias ErrorOutput = (state: AnyTraceable,
                             match: Match,
                             event: AnyTraceable,
                             nextState: AnyTraceable)
    
    struct RankedOutput {
        let state: AnyTraceable,
            match: Match,
            predicateResult: PredicateResult,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action]
        
        var toOutput: Output {
            (state, predicateResult.predicates, event, nextState, actions)
        }
        
        var toErrorOutput: ErrorOutput {
            (state, match, event, nextState)
        }
    }
    
    struct ImplicitClashesError: ValidationError {
        let clashes: ImplicitClashesDictionary
        
        var errorDescription: String? {
            String {
                "The FSM table contains implicit logical clashes (total: \(clashes.count))"
                for (i, clashGroup) in clashes.sorted(by: {
                    $0.key.state.line < $1.key.state.line
                }).enumerated() {
                    let predicates = clashGroup.key.predicates.reduce([]) {
                        $0 + [$1.description]
                    }.sorted().joined(separator: " AND ")
                    
                    ""
                    "Multiple clashing statements imply the same predicates (\(predicates))"
                    ""
                    eachGroupDescription("Context \(i + 1):", clashGroup) { c in
                        c.state.defineDescription
                        c.match.errorDescription
                        c.event.whenDescription
                        c.nextState.thenDescription
                    }
                }
            }
        }
    }
    
    struct ImplicitClashesKey: Hashable {
        let state: AnyTraceable,
            predicates: PredicateSet,
            event: AnyTraceable
        
        init(_ output: Output) {
            self.state = output.state
            self.predicates = output.predicates
            self.event = output.event
        }
    }
    
    typealias ImplicitClashesDictionary = [ImplicitClashesKey: [ErrorOutput]]

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
                                      match: input.match,
                                      predicateResult: predicateResult,
                                      event: input.event,
                                      nextState: input.nextState,
                                      actions: input.actions)
                
                func isRankedClash(_ lhs: RankedOutput) -> Bool {
                    isClash(lhs) && lhs.predicateResult.rank != ro.predicateResult.rank
                }
                
                func isClash(_ lhs: RankedOutput) -> Bool {
                    ImplicitClashesKey(lhs.toOutput) ==
                    ImplicitClashesKey(ro.toOutput)
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
                        clashes[key] = (clashes[key] ?? [clash.toErrorOutput]) + [ro.toErrorOutput]
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
        return (alls + anys.flattened).flattened.combinationsOfAllCases
    }
}

