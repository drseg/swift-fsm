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
    func define(
        _ states: State...,
        @WTABuilder<State, Event> rows: () -> [any WTARowProtocol<State, Event>],
        file: String = #file,
        line: Int = #line
    ) -> TableRow<State, Event> {
        let rows = rows()
        let allModifiers = rows.map { $0.modifiers }
        
        let superStates = allModifiers.map { $0.superStates }.flatten
        let entryActions = allModifiers.map { $0.entryActions }.flatten
        let exitActions = allModifiers.map { $0.exitActions }.flatten
        
        let modifiers = RowModifiers(superStates: superStates,
                                     entryActions: entryActions,
                                     exitActions: exitActions)
        let transitions = formTransitions(states: states,
                                          wtas: rows.wtas(),
                                          file: file,
                                          line: line)
        
        return TableRow(transitions: transitions,
                        modifiers: modifiers)
    }
    
    private func formTransitions(
        states: [State],
        wtas: [WhenThenAction<State, Event>],
        file: String,
        line: Int
    ) -> [Transition<State, Event>] {
        states.reduce(into: [Transition]()) { ts, given in
            wtas.forEach {
                ts.append(Transition(givenState: given,
                                     event: $0.when,
                                     nextState: $0.then,
                                     actions: $0.actions,
                                     file: file,
                                     line: line))
            }
        }
    }
    
    func implements(
        _ ss: SuperState<State, Event>...
    ) -> WTARow<State, Event> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: ss,
                                       entryActions: [],
                                       exitActions: []))
    }
    
    func when(_ events: Event..., then state: State) -> [WhenThen<State, Event>] {
        events.reduce(into: [WhenThen]()) {
            $0.append(WhenThen(when: $1, then: state))
        }
    }
    
    func when(_ events: Event..., then state: State) -> WTARow<State, Event> {
        when(events, then: state, actions: [])
    }
    
    func when(
        _ events: Event...,
        then state: State,
        action: @escaping () -> ()
    ) -> WTARow<State, Event> {
        when(events, then: state, actions: [action])
    }
    
    func when(
        _ events: Event...,
        then state: State,
        actions: [() -> ()]
    ) -> WTARow<State, Event> {
        when(events, then: state, actions: actions)
    }
    
    private func when(
        _ events: [Event],
        then state: State,
        actions: [() -> ()]
    ) -> WTARow<State, Event> {
        WTARow(wtas: events.reduce(into: [WhenThenAction]()) {
            $0.append(WhenThenAction(when: $1,
                                     then: state,
                                     actions: actions))
        }, modifiers: .none)
    }
}
