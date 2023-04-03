//
//  ActionsResolvingNode.swift
//
//  Created by Daniel Segall on 17/03/2023.
//

import Foundation

struct ActionsResolvingNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [Output] {
        var onEntry = [AnyTraceable: [Action]]()
        Set(rest.map(\.state)).forEach { state in
            onEntry[state] = rest.first { $0.state == state }?.onEntry
        }
        
        return rest.reduce(into: []) {
            let actions = $1.state == $1.nextState
            ? $1.actions
            : $1.actions + $1.onExit + (onEntry[$1.nextState] ?? [])
            
            $0.append(($1.state, $1.match, $1.event, $1.nextState, actions))
        }
    }
}
