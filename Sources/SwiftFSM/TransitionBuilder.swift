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
        @WTAPBuilder<S, E> rows: () -> [WTAPRow<S, E>]
    ) -> TableRow<S, E> {
        let rows = rows()
        
        func flatten<T>(_ map: (RowModifiers<S, E>) -> [T]) -> [T] {
            rows.map { $0.modifiers }.map(map).flatten
        }
        
        let wtaps = completeWTAPS(rows.wtaps(), givenStates: states)
        
        let superStates  = flatten { $0.superStates  }.uniqueValues
        let entryActions = flatten { $0.entryActions }
        let exitActions  = flatten { $0.exitActions  }
        
        let modifiers = RowModifiers(superStates: superStates,
                                     entryActions: entryActions,
                                     exitActions: exitActions)
        
        return TableRow(wtaps: wtaps, modifiers: modifiers, givenStates: states)
    }
    
    func completeWTAPS(
        _ wtaps: [WTAP<S, E>],
        givenStates: [S]
    ) -> [WTAP<S, E>] {
        wtaps.reduce(into: [WTAP]()) { wtaps, wtap in
            givenStates.forEach {
                wtaps.append(WTAP(events: wtap.events,
                                  state: wtap.state ?? $0,
                                  actions: wtap.actions,
                                  match: wtap.match,
                                  file: wtap.file,
                                  line: wtap.line))
            }
        }
    }
    
    func onEnter(_ actions: () -> ()...) -> WTAPRow<S, E> {
        WTAPRow(modifiers: RowModifiers(entryActions: actions))
    }
    
    func onExit(_ actions: () -> ()...) -> WTAPRow<S, E> {
        WTAPRow(modifiers: RowModifiers(exitActions: actions))
    }
    
    func implements(_ s: SuperState<S, E>...) -> WTAPRow<S, E> {
        WTAPRow(modifiers: RowModifiers(superStates: s))
    }
    
    func when(
        _ events: E...,
        file: String = #file,
        line: Int = #line
    ) -> Whens<S, E> {
        when(events, file: file, line: line)
    }
    
    func when(
        _ events: [E],
        file: String = #file,
        line: Int = #line
    ) -> Whens<S, E> {
        Whens(events: events, file: file, line: line)
    }
    
    func then() -> Then<S> {
        Then(state: nil)
    }
    
    func then(_ state: S) -> Then<S> {
        Then(state: state)
    }
    
    func then() -> TAPRow<S> {
        .empty
    }
    
    func action(
        _ a1: @escaping () -> (),
        @WTAPBuilder<S, E> _ rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
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
        _ a0: (() -> ())? = nil,
        @WTAPBuilder<S, E> _ rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        actions(
            [a1, a2, a3, a4, a5, a6, a7, a8, a9, a0].compactMap { $0 },
            rows
        )
    }
    
    func actions(
        _ actions: [() -> ()],
        @WTAPBuilder<S, E> _ rows: () -> [WTAPRow<S, E>]
    ) -> [WTAPRow<S, E>] {
        rows().reduce(into: [WTAPRow]()) { wtRows, wtRow in
            if let wtap = wtRow.wtap {
                wtRows.append(WTAPRow(wtap: wtap.addActions(actions)))
            }
        }
    }
}

extension WTAP {
    func addActions(_ a: [() -> ()]) -> Self {
        WTAP(events: events,
             state: state,
             actions: actions + a,
             match: match,
             file: file,
             line: line)
    }
}
