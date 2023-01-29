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
    var transitions = [K: T]()
    
    init(state: State) {
        self.state = state
    }
    
    func buildTransitions(@T.Builder _ content: () -> [K: T]) {
        transitions = content()
    }
    
    func handleEvent(_ event: Event) {
        let key = K(state: state, event: event)
        if let transition = transitions[key] {
            transition.action()
            state = transition.nextState
        }
    }
}
