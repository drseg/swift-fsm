//
//  ActionsNode.swift
//
//  Created by Daniel Segall on 19/02/2023.
//

import Foundation

class ActionsNodeBase {
    let actions: [Action]
    var rest: [any Node<DefaultIO>]
    
    init(actions: [Action] = [], rest: [any Node<DefaultIO>] = []) {
        self.actions = actions
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: [DefaultIO]()) {
            $0.append(
                (match: $1.match,
                 event: $1.event,
                 state: $1.state,
                 actions: actions + $1.actions)
            )
        } ??? defaultIOOutput(actions: actions)
    }
}

class ActionsNode: ActionsNodeBase, Node { }

class ActionsBlockNode: ActionsNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        actions: [Action],
        rest: [any Node<Input>],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(actions: actions, rest: rest)
    }
}
