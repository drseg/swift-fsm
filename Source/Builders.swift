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
    let givenStates: any Collection<S>
}

protocol WTARowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var wta: WhensThenActions<State, Event>? { get }
    var modifiers: RowModifiers<State, Event> { get }
}

protocol WTRowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var wt: WhensThen<State, Event> { get }
    var file: String { get }
    var line: Int { get }
}

struct WTARow<S: SP, E: EP>: WTARowProtocol {
    let wta: WhensThenActions<S, E>?
    let modifiers: RowModifiers<S, E>
}

struct WTRow<S: SP, E: EP>: WTRowProtocol {
    let wt: WhensThen<S, E>
    let file: String
    let line: Int
}

protocol Builder {
    associatedtype T
}

extension Builder {
    static func buildExpression( _ row: [T]) -> [T] {
        row
    }
    
    static func buildExpression( _ row: T) -> [T] {
        [row]
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
    
    static func buildBlock(_ cs: [T]...) -> [T] {
        cs.flatten
    }
}

@resultBuilder
struct TableBuilder<S: SP, E: EP>: Builder {
    typealias T = any TableRowProtocol<S, E>
}

@resultBuilder
struct WTABuilder<S: SP, E: EP>: Builder {
    typealias T = any WTARowProtocol<S, E>
}

@resultBuilder
struct WTBuilder<S: SP, E: EP>: Builder {
    typealias T = any WTRowProtocol<S, E>
}
