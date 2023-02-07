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

struct TableRow<S: SP, E: EP>: TableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    
    var givenStates: any Collection<S> {
        Set(transitions.map(\.givenState))
    }
}

@resultBuilder
class Builder {
    static func buildIf(_ collection: [Any]?) -> [Any] {
        collection ?? []
    }
    
    static func buildEither(first collection: [Any]) -> [Any] {
        collection
    }
    
    static func buildEither(second collection: [Any]) -> [Any] {
        collection
    }
    
    static func buildBlock(_ collections: [Any]...) -> [Any] {
        collections.flatten
    }
}

@resultBuilder
class TableBuilder<S: SP, E: EP>: Builder {
    typealias TRP = TableRowProtocol<S, E>
    
    static func buildExpression( _ row: any TRP) -> [Any] {
        [row]
    }
    
    static func buildExpression( _ rows: [any TRP]) -> [Any] {
        rows
    }
    
    static func buildFinalResult(_ collection: [Any]) -> [Transition<S, E>] {
        let rows = collection as! [any TRP]
        
        return rows.reduce(into: [Transition<S, E>]()) { ts, row in
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
class WTABuilder<S: SP, E: EP>: Builder {
    typealias WTA = WhenThenAction<S, E>
    
    static func buildExpression(_ wtas: [WTA]) -> [Any] {
        wtas
    }
    
    static func buildFinalResult(_ c: [Any]) -> [WTA] {
        c as! [WTA]
    }
}

@resultBuilder
class WTBuilder<S: SP, E: EP>: Builder {
    typealias WT = WhenThen<S, E>
    
    static func buildExpression(_ wtas: [WT]) -> [Any] {
        wtas
    }
    
    static func buildFinalResult(_ c: [Any]) -> [WT] {
        c as! [WT]
    }
}
