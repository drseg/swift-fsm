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
    typealias S = State
    typealias E = Event
    
    func define(
        _ states: S...,
        @WTABuilder<S, E> rows: () -> [any WTARowProtocol<S, E>],
        file: String = #file,
        line: Int = #line
    ) -> TableRow<S, E> {
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
        states: [S],
        wtas: [WhenThenAction<S, E>],
        file: String,
        line: Int
    ) -> [Transition<S, E>] {
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
    
    func onEnter(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: [],
                                       entryActions: actions,
                                       exitActions: []))
    }
    
    func onExit(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: [],
                                       entryActions: [],
                                       exitActions: actions))
    }
    
    func implements(
        _ ss: SuperState<S, E>...
    ) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: ss,
                                       entryActions: [],
                                       exitActions: []))
    }
    
    func when(_ events: E..., then state: S) -> [WhenThen<S, E>] {
        events.reduce(into: [WhenThen]()) {
            $0.append(WhenThen(when: $1, then: state))
        }
    }
    
    func when(_ events: E..., then state: S) -> WTARow<S, E> {
        when(events, then: state, actions: [])
    }
    
    func when(
        _ events: E...,
        then state: S,
        action: @escaping () -> ()
    ) -> WTARow<S, E> {
        when(events, then: state, actions: [action])
    }
    
    func when(
        _ events: E...,
        then state: S,
        actions: [() -> ()]
    ) -> WTARow<S, E> {
        when(events, then: state, actions: actions)
    }
    
    private func when(
        _ events: [E],
        then state: S,
        actions: [() -> ()]
    ) -> WTARow<S, E> {
        WTARow(wtas: events.reduce(into: [WhenThenAction]()) {
            $0.append(WhenThenAction(when: $1,
                                     then: state,
                                     actions: actions))
        }, modifiers: .none)
    }
}
