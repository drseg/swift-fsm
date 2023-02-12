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
    
    var wtas: [WhenThenAction<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
    var file: String { get }
    var line: Int { get }
}

protocol WTRowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var wts: [WhenThen<State, Event>] { get }
    var file: String { get }
    var line: Int { get }
}

struct WTARow<S: SP, E: EP>: WTARowProtocol {
    let wtas: [WhenThenAction<S, E>]
    let modifiers: RowModifiers<S, E>
    let file: String
    let line: Int
}

struct WTRow<S: SP, E: EP>: WTRowProtocol {
    let wts: [WhenThen<S, E>]
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
