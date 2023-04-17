//
//  LazyMRN.swift
//  
//  Created by Daniel Segall on 16/04/2023.
//

import Foundation

final class LazyMatchResolvingNode: Node {
    typealias Output = (condition: (() -> Bool)?,
                        state: AnyTraceable,
                        predicates: PredicateSet,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Output] {
        []
    }
}
