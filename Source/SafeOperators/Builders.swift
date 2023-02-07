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
    
    var transitions: [Transition<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
    var givenStates: any Collection<State> { get }
}

struct TableRow<S: SP, E: EP>: TableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    var givenStates: any Collection<S> {
        Set(transitions.map(\.givenState))
    }
}

@resultBuilder
class Builder<T> {
    static func buildExpression( _ row: T) -> [T] {
        [row]
    }
    
    static func buildExpression( _ rows: [T]) -> [T] {
        rows
    }
    
    static func buildIf(_ collection: [T]?) -> [T] {
        collection ?? []
    }
    
    static func buildEither(first collection: [T]) -> [T] {
        collection
    }
    
    static func buildEither(second collection: [T]) -> [T] {
        collection
    }
    
    static func buildBlock(_ collections: [T]...) -> [T] {
        collections.flatten
    }
}

@resultBuilder
class TableBuilder<S: SP, E: EP>: Builder<any TableRowProtocol<S, E>> {
    typealias TRP = TableRowProtocol<S, E>
    
    static func buildFinalResult(_ rows: [any TRP]) -> [Transition<S, E>] {
        rows.reduce(into: [Transition<S, E>]()) { ts, row in
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
        } + rows.map { $0.transitions }.flatten
    }
}

@resultBuilder
class WTABuilder<S: SP, E: EP>: Builder<WhenThenAction<S, E>> { }

@resultBuilder
class WTBuilder<S: SP, E: EP>: Builder<WhenThen<S, E>> { }
