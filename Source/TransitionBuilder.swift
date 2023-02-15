//
//  TransitionBuilderProtocol.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 12/02/2023.
//

import Foundation

protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}

typealias SP = StateProtocol
typealias EP = EventProtocol

protocol TransitionBuilder {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
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
        
        let superStates  = flatten { $0.superStates  }.uniqueValues
        let entryActions = flatten { $0.entryActions }
        let exitActions  = flatten { $0.exitActions  }
        
        let modifiers = RowModifiers(superStates: superStates,
                                     entryActions: entryActions,
                                     exitActions: exitActions)
        
        let transitions = formTransitions(states: states, rows: rows)
        
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
                    ts.append(contentsOf: wta.makeTransitions(given: given))
                }
            }
        }
    }
    
    func onEnter(_ actions: () -> ()...) -> WTARow<S, E> {
        WTARow(modifiers: RowModifiers(entryActions: actions))
    }
    
    func onExit(_ actions: () -> ()...) -> WTARow<S, E> {
        WTARow(modifiers: RowModifiers(exitActions: actions))
    }
    
    func implements(_ s: SuperState<S, E>...) -> WTARow<S, E> {
        WTARow(modifiers: RowModifiers(superStates: s))
    }
    
    func when(
        _ events: E...,
        file: String = #file,
        line: Int = #line
    ) -> Whens<S, E> {
        Whens(events: events, file: file, line: line)
    }
    
    func then(_ state: S) -> S {
        state
    }
    
    func context(
        action a1: @escaping () -> (),
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        context(actions: [a1], rows)
    }
    
    func context(
        actions a1: @escaping () -> (),
        _ a2: (() -> ())? = nil,
        _ a3: (() -> ())? = nil,
        _ a4: (() -> ())? = nil,
        _ a5: (() -> ())? = nil,
        _ a6: (() -> ())? = nil,
        _ a7: (() -> ())? = nil,
        _ a8: (() -> ())? = nil,
        _ a9: (() -> ())? = nil,
        _ a0: (() -> ())? = nil,
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        context(
            actions: [a1, a2, a3, a4, a5, a6, a7, a8, a9, a0].compactMap { $0 },
            rows
        )
    }
    
    func context(
        actions: [() -> ()],
        @WTBuilder<S, E> _ rows: () -> [any WTRowProtocol<S, E>]
    ) -> [any WTARowProtocol<S, E>] {
        rows().reduce(into: [WTARow]()) { wtRows, wtRow in
            let wta = WhensThenActions(events: wtRow.wt.events,
                                       state: wtRow.wt.state,
                                       actions: actions,
                                       file: wtRow.wt.file,
                                       line: wtRow.wt.line)
            
            wtRows.append(WTARow(wta: wta))
        }
    }
}
