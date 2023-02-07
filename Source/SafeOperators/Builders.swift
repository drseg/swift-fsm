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

protocol TableRowProtocol<State, Event> where State: StateProtocol, Event: EventProtocol {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var givenStates: any Collection<State> { get }
    var transitions: [Transition<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
}

struct TableRowCollection<S: SP, E: EP> {
    let rows: [any TableRowProtocol<S, E>]
    
    var transitions: [Transition<S, E>] {
        rows.map { $0.transitions }.flatten
    }
}

struct TableRow<S: SP, E: EP>: TableRowProtocol, Modifiable {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    
    var givenStates: any Collection<S> {
        Set(transitions.map(\.givenState))
    }
}

@resultBuilder
struct FSMTableBuilder<S: SP, E: EP> {
    typealias TRC = TableRowCollection<S, E>
    
    static func buildExpression<TR>( _ row: TR) -> TRC
    where TR: TableRowProtocol, TR.State == S, TR.Event == E {
        TableRowCollection(rows: [row])
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
        collection.rows.reduce(into: [Transition<S, E>]()) { ts, row in
            row.modifiers.superStates.map(\.wtas).flatten.forEach { wta in
                Set(row.givenStates).forEach { given in
                    ts.append(Transition(givenState: given,
                                         event: wta.when,
                                         nextState: wta.then,
                                         actions: wta.actions))
                }
            }
        } + collection.transitions
    }
}
