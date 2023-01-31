//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

class FSMBase<State, Event> where State: Hashable, Event: Hashable {
    typealias T = Transition<State, Event>
    typealias K = T.Key<State, Event>
    
    var state: State
    var transitions = [K: T]()
    
    fileprivate init(initialState state: State) {
        self.state = state
    }
    
    fileprivate func handleEvent(_ event: Event) {
        let key = K(state: state, event: event)
        if let t = transitions[key] {
            t.action()
            state = t.nextState
        }
    }
    
    func buildTransitions(@T.Builder _ content: () -> [K: T]) {
        transitions = content()
    }
}

final class FSM<State, Event>: FSMBase<State, Event> where State: Hashable, Event: Hashable {
    override init(initialState state: State) {
        super.init(initialState: state)
    }
    
    override func handleEvent(_ event: Event) {
        super.handleEvent(event)
    }
}

final class UnsafeFSM: FSMBase<Unsafe.AnyState, Unsafe.AnyEvent> {
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erased)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        super.handleEvent(event.erased)
    }
}
