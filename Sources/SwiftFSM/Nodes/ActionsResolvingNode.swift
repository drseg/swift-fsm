//
//  ActionsResolvingNode.swift
//
//  Created by Daniel Segall on 17/03/2023.
//

import Foundation

struct IntermediateIO {
    let state: AnyTraceable,
        match: Match,
        event: AnyTraceable,
        nextState: AnyTraceable,
        actions: [Action]
    
    init(
        _ state: AnyTraceable,
        _ match: Match,
        _ event: AnyTraceable,
        _ nextState: AnyTraceable,
        _ actions: [Action]
    ) {
        self.state = state
        self.match = match
        self.event = event
        self.nextState = nextState
        self.actions = actions
    }
}

struct ActionsResolvingNode: Node {
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [IntermediateIO] {
        var onEntry = [AnyTraceable: [Action]]()
        Set(rest.map(\.state)).forEach { state in
            onEntry[state] = rest.first { $0.state == state }?.onEntry
        }
        
        return rest.reduce(into: []) {
            let actions = $1.state == $1.nextState
            ? $1.actions
            : $1.actions + $1.onExit + (onEntry[$1.nextState] ?? [])
            
            $0.append(IntermediateIO($1.state, $1.match, $1.event, $1.nextState, actions))
        }
    }
}
