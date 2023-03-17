//
//  TransitionNode.swift
//
//  Created by Daniel Segall on 17/03/2023.
//

import Foundation

struct TransitionNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [Output] {
        []
    }
}
