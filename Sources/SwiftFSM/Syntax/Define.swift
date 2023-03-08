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
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line
        ) {
            self.init([s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      elements: [],
                      file: file,
                      line: line)
        }
        
        init(_ s1: State,
             _ rest: State...,
             superState: SuperState? = nil,
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> ([any MWTAProtocol])
        ) {
            self.init(states: [s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      file: file,
                      line: line,
                      block)
        }
        
        init(states: [State],
             superState: SuperState? = nil,
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Internal.MWTABuilder _ block: () -> ([any MWTAProtocol])
        ) {
            let elements = block()
            
            self.init(states,
                      superState: elements.isEmpty ? nil : superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      elements: elements,
                      file: file,
                      line: line)
        }
        
        init(_ states: [State],
                         superState: SuperState?,
                         entryActions: [() -> ()],
                         exitActions: [() -> ()],
                         elements: [any MWTAProtocol],
                         file: String = #file,
                         line: Int = #line
        ) {
            var dNode = DefineNode(entryActions: entryActions,
                                   exitActions: exitActions,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            let isValid = superState != nil || !elements.isEmpty
            
            if isValid {
                func eraseToAnyTraceable(_ s: State) -> AnyTraceable {
                    AnyTraceable(base: s, file: file, line: line)
                }
                
                let states = states.map(eraseToAnyTraceable)
                let rest = superState?.nodes ?? [] + elements.nodes
                let gNode = GivenNode(states: states, rest: rest)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
}
