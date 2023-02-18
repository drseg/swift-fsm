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
    
#warning("variadics seem to mess with highlighting, should allow arrays everywhere")
    func define(
        _ states: S...,
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> rows: () -> [WTAMRow<S, E>]
    ) -> TableRow<S, E> {
        let rows = rows()
        
        func flatten<T>(_ map: (RowModifiers<S, E>) -> [T]) -> [T] {
            rows.map { $0.modifiers }.map(map).flatten
        }
        
        let wtams = completeWTAMS(rows.wtams(), givenStates: states)
        
        let superStates  = flatten { $0.superStates  }.uniqueValues
        let entryActions = flatten { $0.entryActions }
        let exitActions  = flatten { $0.exitActions  }
        
        let modifiers = RowModifiers(superStates: superStates,
                                     entryActions: entryActions,
                                     exitActions: exitActions)
        
        return modifiers == .none && wtams.isEmpty
        ? .error(file: file, line: line)
        : .init(wtams: wtams, modifiers: modifiers, givenStates: states)
    }
    
    func completeWTAMS(
        _ wtams: [WTAM<S, E>],
        givenStates: [S]
    ) -> [WTAM<S, E>] {
        wtams.reduce(into: [WTAM]()) { wtams, wtam in
            givenStates.forEach {
                wtams.append(wtam.replaceDefaultState(with: $0))
            }
        }
    }
    
    func onEnter(_ actions: () -> ()...) -> WTAMRow<S, E> {
        WTAMRow(modifiers: RowModifiers(entryActions: actions))
    }
    
    func onExit(_ actions: () -> ()...) -> WTAMRow<S, E> {
        WTAMRow(modifiers: RowModifiers(exitActions: actions))
    }
    
    func implements(_ s: SuperState<S, E>...) -> WTAMRow<S, E> {
        WTAMRow(modifiers: RowModifiers(superStates: s))
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
    
    func then() -> TAM<S> {
        .init()
    }
    
    func action(
        _ a1: @escaping () -> (),
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> _ rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        actions([a1], file: file, line: line, rows)
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
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> _ rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        actions(
            [a1, a2, a3, a4, a5, a6, a7, a8, a9, a0].compactMap { $0 },
            file: file,
            line: line,
            rows
        )
    }
    
    func actions(
        _ actions: [() -> ()],
        file: String = #file,
        line: Int = #line,
        @WTAMBuilder<S, E> _ rows: () -> [WTAMRow<S, E>]
    ) -> [WTAMRow<S, E>] {
        rows().reduce(into: [WTAMRow<S, E>]()) { wtRows, wtRow in
            if let wtam = wtRow.wtam {
                wtRows.append(WTAMRow(wtam: wtam.addActions(actions)))
            }
        } ??? [.error(file: file, line: line)]
    }
}
