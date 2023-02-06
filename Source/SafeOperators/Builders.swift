//
//  Builders.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 05/02/2023.
//

import Foundation

@resultBuilder
struct WTABuilder<S: SP, E: EP> {
    static func buildBlock<E>(
        _ wtas: [WhenThenAction<S, E>]...
    ) -> [WhenThenAction<S, E>] {
        wtas.flatten
    }
}

@resultBuilder
struct WTBuilder<S: SP, E: EP> {
    static func buildBlock(
        _ wts: [WhenThen<S, E>]...
    ) -> [WhenThen<S, E>] {
        wts.flatten
    }
}

protocol FSMTableRowProtocol {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
}

struct FSMTableRowCollection<S: SP, E: EP> {
    let rows: [FSMTableRow<S, E>]
    
    var transitions: [Transition<S, E>] {
        rows.map(\.transitions).flatten
    }
}

struct FSMTableRow<S: SP, E: EP>: FSMTableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    
    var startStates: Set<S> {
        Set(transitions.map { $0.givenState })
    }
}

@resultBuilder
struct FSMTableBuilder<S: SP, E: EP> {
    typealias TRC = FSMTableRowCollection<S, E>
    
    static func buildExpression<TG: FSMTableRowProtocol>(
        _ e: TG
    ) -> TRC where TG.State == S, TG.Event == E {
        FSMTableRowCollection(rows: [FSMTableRow(transitions: e.transitions,
                                                 modifiers: e.modifiers)])
    }
    
    static func buildExpression(_ rows: [FSMTableRow<S, E>]) -> TRC {
        FSMTableRowCollection(rows: rows)
    }
    
    static func buildIf(_ components: TRC?) -> TRC {
        FSMTableRowCollection(rows: components?.rows ?? [])
    }
    
    static func buildEither(first component: TRC) -> TRC {
        component
    }
    
    static func buildEither(second component: TRC) -> TRC {
        component
    }
    
    static func buildBlock(_ components: TRC...) -> TRC {
        FSMTableRowCollection(rows: components.map(\.rows).flatten)
    }
}
