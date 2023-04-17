//
//  DefineNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

final class DefineNode: NeverEmptyNode {
    struct Output {
        let state: AnyTraceable,
            match: Match,
            event: AnyTraceable,
            nextState: AnyTraceable,
            actions: [Action],
            onEntry: [Action],
            onExit: [Action]
        
        init(_ state: AnyTraceable,
             _ match: Match,
             _ event: AnyTraceable,
             _ nextState: AnyTraceable,
             _ actions: [Action],
             _ onEntry: [Action],
             _ onExit: [Action]
        ) {
            self.state = state
            self.match = match
            self.event = event
            self.nextState = nextState
            self.actions = actions
            self.onEntry = onEntry
            self.onExit = onExit
        }
    }
    
    let onEntry: [Action]
    let onExit: [Action]
    var rest: [any Node<GivenNode.Output>] = []
    
    let caller: String
    let file: String
    let line: Int
        
    private var errors: [Error] = []
    
    init(
        onEntry: [Action],
        onExit: [Action],
        rest: [any Node<GivenNode.Output>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.onEntry = onEntry
        self.onExit = onExit
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }
    
    func combinedWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        let output = rest.reduce(into: [Output]()) {
            if let match = finalise($1.match) {
                $0.append(
                    Output($1.state, match, $1.event, $1.nextState, $1.actions, onEntry, onExit)
                )
            }
        }
        
        return errors.isEmpty ? output : []
    }
    
    private func finalise(_ m: Match) -> Match? {
        switch m.finalised() {
        case .failure(let e): errors.append(e); return nil
        case .success(let m): return m
        }
    }
    
    func validate() -> [Error] {
        makeError(if: rest.isEmpty) + errors
    }
}
