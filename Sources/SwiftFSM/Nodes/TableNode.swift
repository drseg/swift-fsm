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
        
        let output = rest.reduce(into: [Output]()) { result, input in
            input.match.allPredicateCombinations(allCases).forEach {
                result.append(
                    (state: input.state,
                     predicates: $0.predicates,
                     event: input.event,
                     nextState: input.nextState,
                     actions: input.actions)
                )
            }
        }
        
        return output
    }
}
