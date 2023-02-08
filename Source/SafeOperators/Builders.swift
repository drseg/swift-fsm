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

protocol Builder {
    associatedtype T
}

extension Builder {
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
struct TableBuilder<S: SP, E: EP>: Builder {
    typealias T = any TableRowProtocol<S, E>
    
    static func buildExpression( _ row: T) -> [T] {
        [row]
    }
}

@resultBuilder
struct WTABuilder<S: SP, E: EP>: Builder {
    typealias T = WhenThenAction<S, E>
}

@resultBuilder
struct WTBuilder<S: SP, E: EP>: Builder {
    typealias T = WhenThen<S, E>
}
