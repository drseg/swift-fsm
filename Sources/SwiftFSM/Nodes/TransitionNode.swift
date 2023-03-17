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
        rest.reduce(into: [Output]()) {
            let actions = $1.state == $1.nextState
            ? $1.actions
            : $1.actions + $1.exitActions
            
            $0.append(($1.state, $1.match, $1.event, $1.nextState, actions))
        }
    }
}
