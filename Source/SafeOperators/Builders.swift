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

protocol TableRowProtocol {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
}

struct TableRowCollection<S: SP, E: EP> {
    let rows: [TableRow<S, E>]
    
    var transitions: [Transition<S, E>] {
        rows.map(\.transitions).flatten
    }
}

struct TableRow<S: SP, E: EP>: TableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    
    var startStates: Set<S> {
        Set(transitions.map { $0.givenState })
    }
}

@resultBuilder
struct FSMTableBuilder<S: SP, E: EP> {
    typealias TRC = TableRowCollection<S, E>
    
    static func buildExpression<TR>( _ row: TR) -> TRC
    where TR: TableRowProtocol, TR.State == S, TR.Event == E {
        TableRowCollection(rows: [
            TableRow(
                transitions: row.transitions,
                modifiers: row.modifiers
            )
        ])
    }
    
    static func buildExpression(_ rows: [TableRow<S, E>]) -> TRC {
        TableRowCollection(rows: rows)
    }
    
    static func buildIf(_ collection: TRC?) -> TRC {
        TableRowCollection(rows: collection?.rows ?? [])
    }
    
    static func buildEither(first collection: TRC) -> TRC {
        collection
    }
    
    static func buildEither(second collection: TRC) -> TRC {
        collection
    }
    
    static func buildBlock(_ collections: TRC...) -> TRC {
        TableRowCollection(rows: collections.map(\.rows).flatten)
    }
    
    static func buildFinalResult(_ collection: TRC) -> [Transition<S, E>] {
        collection.transitions
    }
}
