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
                        modifiers: modifiers,
                        givenStates: states)
    }
    
    private func formTransitions(
        states: [S],
        rows: [any WTARowProtocol<S, E>]
    ) -> [Transition<S, E>] {
        states.reduce(into: [Transition]()) { ts, given in
            rows.forEach { row in
                if let wta = row.wta {
                    wta.events.forEach {
                        ts.append(Transition(givenState: given,
                                             event: $0,
                                             nextState: wta.state,
                                             actions: wta.actions,
                                             file: row.file,
                                             line: row.line))
                    }
                }
            }
        }
    }
    
    func onEnter(_ actions: () -> ()...) -> WTARow<S, E> {
         onEnter(actions)
    }
    
    func onEnter(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wta: nil,
               modifiers: RowModifiers(superStates: [],
                                       entryActions: actions,
                                       exitActions: []),
               file: #file, line: #line)
    }
    
    
    func onExit(_ actions: () -> ()...) -> WTARow<S, E> {
        onExit(actions)
    }
    
    func onExit(_ actions: [() -> ()]) -> WTARow<S, E> {
        WTARow(wta: nil,
               modifiers: RowModifiers(superStates: [],
                                       entryActions: [],
                                       exitActions: actions),
               file: #file, line: #line)
    }
    
    func implements(
        _ ss: SuperState<S, E>...
    ) -> WTARow<S, E> {
        WTARow(wta: nil,
               modifiers: RowModifiers(superStates: ss,
                                       entryActions: [],
                                       exitActions: []),
               file: #file, line: #line)
    }
    
    func when(_ events: E..., file: String = #file, line: Int = #line) -> Whens<S, E> {
        Whens(events: events, file: file, line: line)
    }
    
    func then(_ state: S) -> S {
        state
    }
    
    func when(
        _ events: E...,
        then state: S,
        file: String = #file,
        line: Int = #line
    ) -> any WTRowProtocol<S, E> {
        WTRow(
            wt: WhensThen(events: events, state: state),
            file: file,
            line: line
        )
    }
    
    func action(
        _ a1: @escaping () -> (),
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        actions([a1], rows)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ a2: (() -> ())? = nil,
        _ a3: (() -> ())? = nil,
        _ a4: (() -> ())? = nil,
        _ a5: (() -> ())? = nil,
        _ a6: (() -> ())? = nil,
        _ a7: (() -> ())? = nil,
        _ a8: (() -> ())? = nil,
        _ a9: (() -> ())? = nil,
        _ a10: (() -> ())? = nil,
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        actions([a1, a2, a3, a4, a5, a6, a7, a8, a9, a10].compactMap { $0 },
               rows)
    }
    
    func actions(
        _ actions: [() -> ()],
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        rows().reduce(into: [WTARow]()) { wtRows, wtRow in
            let wta = WhensThenActions(events: wtRow.wt.events,
                                     state: wtRow.wt.state,
                                     actions: actions)
            
            wtRows.append(
                WTARow(wta: wta,
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
        WTARow(wta: WhensThenActions(events: events, state: state, actions: actions),
               modifiers: .none, file: file, line: line)
    }
}
