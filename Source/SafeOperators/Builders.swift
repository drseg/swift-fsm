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

protocol TransitionGroup {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get }
    var entryActions: [() -> ()] { get }
    var exitActions: [() -> ()] { get }
}

@resultBuilder
struct TransitionBuilder<S: SP, E: EP> {
    typealias TRC = FSMTableRowCollection<S, E>
    
    static func buildExpression<TG: TransitionGroup>(
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
