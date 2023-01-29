//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

class GenericFSM<State, Event> where State: Hashable, Event: Hashable {
    typealias T = Transition<State, Event>
    typealias K = T.Key<State, Event>
    
    var state: State
    
    init(_ state: State) {
        self.state = state
    }
    
    func build(
        @T.Builder _ content: () -> [K: T]
    ) -> [K: T] {
        content()
    }
    
    func handleEvent(_ event: Event) {
        
    }
}
