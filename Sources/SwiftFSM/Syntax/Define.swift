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
             _ rest: State...,
             superState: SuperState,
             onEntry: [() -> ()],
             onExit: [() -> ()],
             file: String = #file,
             line: Int = #line
        ) {
            self.init([s1] + rest,
                      superState: superState,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: [],
                      file: file,
                      line: line)
        }
        
        init(_ s1: State,
             _ rest: State...,
             superState: SuperState? = nil,
             onEntry: [() -> ()] = [],
             onExit: [() -> ()] = [],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            self.init(states: [s1] + rest,
                      superState: superState,
                      onEntry: onEntry,
                      onExit: onExit,
                      file: file,
                      line: line,
                      block)
        }
        
        init(states: [State],
             superState: SuperState? = nil,
             onEntry: [() -> ()],
             onExit: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> [any MWTA]
        ) {
            let elements = block()
            
            self.init(states,
                      superState: elements.isEmpty ? nil : superState,
                      onEntry: onEntry,
                      onExit: onExit,
                      elements: elements,
                      file: file,
                      line: line)
        }
        
        init(_ states: [State],
             superState: SuperState?,
             onEntry: [() -> ()],
             onExit: [() -> ()],
             elements: [any MWTA],
             file: String = #file,
             line: Int = #line
        ) {
            let dNode = DefineNode(onEntry: onEntry,
                                   onExit: onExit,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            let isValid = superState != nil || !elements.isEmpty
            
            if isValid {
                func eraseToAnyTraceable(_ s: State) -> AnyTraceable {
                    AnyTraceable(s, file: file, line: line)
                }
                
                let states = states.map(eraseToAnyTraceable)
                let rest = (superState?.nodes ?? []) + elements.nodes
                let gNode = GivenNode(states: states, rest: rest)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
}
