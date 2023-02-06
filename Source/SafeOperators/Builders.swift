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
        wtas.flatMap { $0 }
    }
}

@resultBuilder
struct WTBuilder<S: SP, E: EP> {
    static func buildBlock(
        _ wts: [WhenThen<S, E>]...
    ) -> [WhenThen<S, E>] {
        wts.flatMap { $0 }
    }
}

protocol FSMTableRowProtocol {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get }
    var entryActions: [() -> ()] { get }
    var exitActions: [() -> ()] { get }
}

struct FSMTableRowCollection<S: SP, E: EP> {
    let rows: [FSMTableRow<S, E>]
    
    var transitions: [Transition<S, E>] {
        rows.map(\.transitions).flatMap { $0 }
    }
}

struct FSMTableRow<S: SP, E: EP>: FSMTableRowProtocol {
    let transitions: [Transition<S, E>]
    let entryActions: [() -> ()]
    let exitActions: [() -> ()]
    
    var startStates: Set<S> {
        Set(transitions.map { $0.givenState })
    }
    
    init(
        _ transitions: [Transition<S, E>],
        entryActions: [() -> ()] = [],
        exitActions: [() -> ()] = []
    ) {
        self.transitions = transitions
        self.entryActions = entryActions
        self.exitActions = exitActions
    }
}

@resultBuilder
struct FSMTableBuilder<S: SP, E: EP> {
    typealias TRC = FSMTableRowCollection<S, E>
    
    static func buildExpression<TG: FSMTableRowProtocol>(
        _ e: TG
    ) -> TRC where TG.State == S, TG.Event == E {
        FSMTableRowCollection(rows: [FSMTableRow(e.transitions,
                                                 entryActions: e.entryActions,
                                                 exitActions: e.exitActions)])
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
        FSMTableRowCollection(rows: components.map(\.rows).flatMap { $0 })
    }
}
