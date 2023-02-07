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
struct TableBuilder<S: SP, E: EP> {
    typealias TRP = TableRowProtocol<S, E>
    
    static func buildExpression( _ row: any TRP) -> [any TRP] {
        [row]
    }
    
    static func buildIf(_ collection: [any TRP]?) -> [any TRP] {
        collection ?? []
    }
    
    static func buildEither(first collection: [any TRP]) -> [any TRP] {
        collection
    }
    
    static func buildEither(second collection: [any TRP]) -> [any TRP] {
        collection
    }
    
    static func buildBlock(_ collections: [any TRP]...) -> [any TRP] {
        collections.flatten
    }
    
    static func buildFinalResult(_ collection: [any TRP]) -> [Transition<S, E>] {
        collection.reduce(into: [Transition<S, E>]()) { ts, row in
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
        } + collection.map { $0.transitions }.flatten
    }
}

protocol SlowBuilder {
    associatedtype T
}

extension SlowBuilder {
    static func buildIf(_ collection: [T]?) -> [T] {
        collection ?? []
    }
    
    static func buildEither(first collection: [T]) -> [T] {
        collection
    }
    
    static func buildEither(second collection: [T]) -> [T] {
        collection
    }
    
    static func buildBlock(_ cs: [T]...) -> [T] {
        cs.flatten
    }
}

@resultBuilder
class WTABuilder<S: SP, E: EP>: SlowBuilder {
    typealias T = WhenThenAction<S, E>
}

@resultBuilder
class WTBuilder<S: SP, E: EP>: SlowBuilder {
    typealias T = WhenThen<S, E>
}
