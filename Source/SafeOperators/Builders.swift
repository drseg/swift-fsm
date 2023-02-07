//
//  Builders.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 05/02/2023.
//

import Foundation

protocol TableRowProtocol<State, Event> {
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

struct TableRow<S: SP, E: EP>: TableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    
    var givenStates: any Collection<S> {
        Set(transitions.map(\.givenState))
    }
}

@resultBuilder
struct TableBuilder<S: SP, E: EP> {
    typealias TRC = TableRowCollection<S, E>
    
    static func buildExpression( _ row: any TableRowProtocol<S, E>) -> TRC {
        TRC(rows: [row])
    }
    
    static func buildExpression( _ rows: [any TableRowProtocol<S, E>]) -> TRC {
        TRC(rows: rows)
    }
    
    static func buildIf(_ collection: TRC?) -> TRC {
        TRC(rows: collection?.rows ?? [])
    }
    
    static func buildEither(first collection: TRC) -> TRC {
        collection
    }
    
    static func buildEither(second collection: TRC) -> TRC {
        collection
    }
    
    static func buildBlock(_ collections: TRC...) -> TRC {
        TRC(rows: collections.map(\.rows).flatten)
    }
    
    static func buildFinalResult(_ collection: TRC) -> [Transition<S, E>] {
        collection.rows.reduce(into: [Transition<S, E>]()) { ts, row in
            row.modifiers.superStates.map(\.wtas).flatten.forEach { wta in
                row.givenStates.forEach { given in
                    ts.append(
                        Transition(givenState: given,
                                   event: wta.when,
                                   nextState: wta.then,
                                   actions: wta.actions)
                    )
                }
            }
        } + collection.transitions
    }
}

@resultBuilder
class DefaultBuilder<C> {
    static func buildBlock(_ cs: [C]...) -> [C] {
        cs.flatten
    }
}

@resultBuilder
class WTABuilder<S: SP, E: EP>: DefaultBuilder<WhenThenAction<S, E>> { }

@resultBuilder
class WTBuilder<S: SP, E: EP>: DefaultBuilder<WhenThen<S, E>> { }
