//
//  Define.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Define<State: Hashable> {
        let node: DefineNode
        
        init(_ s1: State,
             _ rest1: State...,
             superStates: SuperState,
             _ rest2: SuperState...,
             onEntry: [() -> ()],
             onExit: [() -> ()],
             file: String = #file,
             line: Int = #line
        ) {
            self.init([s1] + rest1,
                      superStates: [superStates] + rest2,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: [],
                      file: file,
                      line: line)
        }
        
        init(_ s1: State,
             _ rest: State...,
             superStates: SuperState...,
             onEntry: [() -> ()] = [],
             onExit: [() -> ()] = [],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            self.init(states: [s1] + rest,
                      superStates: superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      file: file,
                      line: line,
                      block)
        }
        
        init(states: [State],
             superStates: [SuperState] = [],
             onEntry: [() -> ()],
             onExit: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            let elements = block()
            
            self.init(states,
                      superStates: elements.isEmpty ? [] : superStates,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: elements,
                      file: file,
                      line: line)
        }
        
        init(_ states: [State],
             superStates: [SuperState],
             onEntry: [() -> ()],
             onExit: [() -> ()],
             elements: [any MWTA],
             file: String = #file,
             line: Int = #line
        ) {
            let onEntry = onEntry + superStates.map(\.entryActions).flattened
            let onExit = onExit + superStates.map(\.exitActions).flattened
            
            let dNode = DefineNode(onEntry: onEntry,
                                   onExit: onExit,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            let isValid = !superStates.isEmpty || !elements.isEmpty
            
            if isValid {
                func eraseToAnyTraceable(_ s: State) -> AnyTraceable {
                    AnyTraceable(s, file: file, line: line)
                }
                
                let states = states.map(eraseToAnyTraceable)
                let rest = superStates.map(\.nodes).flattened + elements.nodes
                let gNode = GivenNode(states: states, rest: rest)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
}
