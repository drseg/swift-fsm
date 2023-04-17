//
//  LazyMRN.swift
//  
//  Created by Daniel Segall on 16/04/2023.
//

import Foundation

final class LazyMatchResolvingNode: Node {
    var rest: [any Node<Input>]
    
    init(rest: [any Node<Input>] = []) {
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [SemanticValidationNode.Output]) -> [Transition] {
        []
    }
}
