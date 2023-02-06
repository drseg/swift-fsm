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
    typealias T = Transition<S, E>
    
    static func buildExpression(_ expression: [T]) -> FSMTableRow<S, E> {
        FSMTableRow(expression)
    }
    
    static func buildExpression<TG: TransitionGroup>(
        _ e: TG
    ) -> FSMTableRow<S, E> where TG.State == S, TG.Event == E {
        FSMTableRow(e.transitions,
                    entryActions: e.entryActions,
                    exitActions: e.exitActions)
    }
    
    static func buildIf(_ components: [T]?) -> FSMTableRow<S, E> {
        FSMTableRow(components ?? [])
    }
    
    static func buildEither(first component: [T]) -> FSMTableRow<S, E>{
        FSMTableRow(component)
    }
    
    static func buildEither(second component: [T]) -> FSMTableRow<S, E> {
        FSMTableRow(component)
    }
    
    static func buildBlock(_ components: FSMTableRow<S, E>...) -> [T] {
        Array(components.map(\.transitions).joined())
    }
}
