//
//  DefineNode.swift
//
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

final class DefineNode: NeverEmptyNode {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action],
                        entryActions: [Action],
                        exitActions: [Action])
    
    let entryActions: [Action]
    let exitActions: [Action]
    var rest: [any Node<GivenNode.Output>] = []
    
    let caller: String
    let file: String
    let line: Int
        
    private var errors: [Error] = []
    
    init(
        entryActions: [Action],
        exitActions: [Action],
        rest: [any Node<GivenNode.Output>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.entryActions = entryActions
        self.exitActions = exitActions
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }
    
    func combinedWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append(
                (state: $1.state,
                 match: finalised($1.match),
                 event: $1.event,
                 nextState: $1.nextState,
                 actions: $1.actions,
                 entryActions: $1.state == $1.nextState ? [] : entryActions,
                 exitActions: $1.state == $1.nextState ? [] : exitActions)
            )
        }
    }
    
    private func finalised(_ m: Match) -> Match {
        switch m.finalise() {
        case .failure(let e): errors.append(e); return Match()
        case .success(let m): return m
        }
    }
    
    func validate() -> [Error] {
        makeError(if: rest.isEmpty) + errors
    }
}
