//
//  Define.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Define<State: Hashable> {
        let node: DefineNode
        
        init(_ state: State,
             adopts superStates: SuperState,
             _ rest: SuperState...,
             onEntry: [Action],
             onExit: [Action],
             file: String = #file,
             line: Int = #line
        ) {
            self.init(state,
                      adopts: [superStates] + rest,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: [],
                      file: file,
                      line: line)
        }
        
        init(_ state: State,
             adopts superStates: SuperState...,
             onEntry: [Action] = [],
             onExit: [Action] = [],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            self.init(state: state,
                      adopts: superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      file: file,
                      line: line,
                      block)
        }
        
        init(state: State,
             adopts superStates: [SuperState] = [],
             onEntry: [Action],
             onExit: [Action],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            let elements = block()
            
            self.init(state,
                      adopts: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: elements,
                      file: file,
                      line: line)
        }
        
        init(_ state: State,
             adopts superStates: [SuperState],
             onEntry: [Action],
             onExit: [Action],
             elements: [any MWTA],
             file: String = #file,
             line: Int = #line
        ) {
            let onEntry = onEntry + superStates.map(\.onEntry).flattened
            let onExit = onExit + superStates.map(\.onExit).flattened
            
            let dNode = DefineNode(onEntry: onEntry,
                                   onExit: onExit,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            let isValid = !superStates.isEmpty || !elements.isEmpty
            
            if isValid {
                let state = AnyTraceable(state, file: file, line: line)
                let rest = superStates.map(\.nodes).flattened + elements.nodes
                let gNode = GivenNode(states: [state], rest: rest)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
}
