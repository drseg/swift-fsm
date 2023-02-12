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

protocol ComplexTransitionBuilder: TransitionBuilder {
    associatedtype Predicate: StateProtocol
}

extension TransitionBuilder {
    typealias S = State
    typealias E = Event
    
    func define(
        _ states: S...,
        @WTABuilder<S, E> rows: () -> [any WTARowProtocol<S, E>]
    ) -> TableRow<S, E> {
        let rows = rows()
        
        func flatten<T>(_ map: (RowModifiers<S, E>) -> [T]) -> [T] {
            rows.map { $0.modifiers }.map(map).flatten
        }
        
        let superStates = flatten { $0.superStates }.uniqueValues
        let entryActions = flatten { $0.entryActions }
        let exitActions = flatten { $0.exitActions }
        
        let modifiers = RowModifiers(superStates: superStates,
                                     entryActions: entryActions,
                                     exitActions: exitActions)
        let transitions = formTransitions(states: states,
                                          rows: rows)
        
        return TableRow(transitions: transitions,
                        modifiers: modifiers)
    }
    
    private func formTransitions(
        states: [S],
        rows: [any WTARowProtocol<S, E>]
    ) -> [Transition<S, E>] {
        states.reduce(into: [Transition]()) { ts, given in
            rows.forEach { row in
                row.wtas.forEach {
                    ts.append(Transition(givenState: given,
                                         event: $0.when,
                                         nextState: $0.then,
                                         actions: $0.actions,
                                         file: row.file,
                                         line: row.line))
                }
            }
        }
    }
    
    func onEnter(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: [],
                                       entryActions: actions,
                                       exitActions: []),
               file: #file, line: #line)
    }
    
    func onExit(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: [],
                                       entryActions: [],
                                       exitActions: actions),
               file: #file, line: #line)
    }
    
    func implements(
        _ ss: SuperState<S, E>...
    ) -> WTARow<S, E> {
        WTARow(wtas: [],
               modifiers: RowModifiers(superStates: ss,
                                       entryActions: [],
                                       exitActions: []),
               file: #file, line: #line)
    }
    
    func when(
        _ events: E...,
        then state: S,
        file: String = #file,
        line: Int = #line
    ) -> any WTRowProtocol<S, E> {
        WTRow(
            wts: events.reduce(into: [WhenThen]()) {
                $0.append(WhenThen(when: $1, then: state))
            },
            file: file,
            line: line
        )
    }
    
    func action(
        _ actions: [() -> ()],
        @WTBuilder<S, E> rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        rows().reduce(into: [WTARow]()) { wtRows, wtRow in
            let wtas = wtRow.wts.reduce(into: [WhenThenAction<S, E>]()) {
                $0.append(
                    WhenThenAction(when: $1.when,
                                   then: $1.then,
                                   actions: actions)
                )
            }
            
            wtRows.append(
                WTARow(wtas: wtas,
                       modifiers: .none,
                       file: wtRow.file,
                       line: wtRow.line))
        }
    }
    
    func when(
        _ events: E...,
        then state: S,
        file: String = #file,
        line: Int = #line
    ) -> WTARow<S, E> {
        when(events, then: state, actions: [], file: file, line: line)
    }
    
    func when(
        _ events: E...,
        then state: S,
        action: @escaping () -> (),
        file: String = #file,
        line: Int = #line
    ) -> WTARow<S, E> {
        when(events, then: state, actions: [action], file: file, line: line)
    }
    
    func when(
        _ events: E...,
        then state: S,
        actions: () -> ()...,
        file: String = #file,
        line: Int = #line
    ) -> WTARow<S, E> {
        when(events, then: state, actions: actions, file: file, line: line)
    }
    
    func when(
        _ events: E...,
        then state: S,
        actions: () -> ([() -> ()]),
        file: String = #file,
        line: Int = #line
    ) -> WTARow<S, E> {
        when(events, then: state, actions: actions(), file: file, line: line)
    }
    
    func when(
        _ events: E...,
        then state: S,
        actions: [() -> ()],
        file: String = #file,
        line: Int = #line
    ) -> WTARow<S, E> {
        when(events, then: state, actions: actions, file: file, line: line)
    }
    
    private func when(
        _ events: [E],
        then state: S,
        actions: [() -> ()],
        file: String,
        line: Int
    ) -> WTARow<S, E> {
        WTARow(wtas: events.reduce(into: [WhenThenAction]()) {
            $0.append(WhenThenAction(when: $1,
                                     then: state,
                                     actions: actions))
        }, modifiers: .none, file: file, line: line)
    }
}
