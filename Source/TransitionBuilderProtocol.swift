//
//  TransitionBuilderProtocol.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 12/02/2023.
//

import Foundation

protocol TransitionBuilder {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
}

extension TransitionBuilder {
    func when(_ events: Event..., then state: State) -> [WhenThenAction<State, Event>] {
        when(events, then: state, actions: [])
    }
    
    func when(
        _ events: Event...,
        then state: State,
        action: @escaping () -> ()
    ) -> [WhenThenAction<State, Event>] {
        when(events, then: state, actions: [action])
    }
    
    func when(
        _ events: Event...,
        then state: State,
        actions: [() -> ()]
    ) -> [WhenThenAction<State, Event>] {
        when(events, then: state, actions: actions)
    }
    
    private func when(
        _ events: [Event],
        then state: State,
        actions: [() -> ()]
    ) -> [WhenThenAction<State, Event>] {
        events.reduce(into: [WhenThenAction]()) {
            $0.append(WhenThenAction(when: $1,
                                     then: state,
                                     actions: actions))
        }
    }
}
