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
}

@resultBuilder
struct TransitionBuilder<S: SP, E: EP> {
    typealias T = Transition<S, E>
    
    struct _TGroup {
        fileprivate let transitions: [T]
        fileprivate init(_ transitions: [T]) {
            self.transitions = transitions
        }
    }
    
    static func buildExpression(_ expression: [T]) -> _TGroup {
        _TGroup(expression)
    }
    
    static func buildExpression<TG: TransitionGroup>(
        _ expression: TG
    ) -> _TGroup where TG.State == S, TG.Event == E {
        _TGroup(expression.transitions)
    }
    
    static func buildIf(_ components: [T]?) -> _TGroup {
        _TGroup(components ?? [])
    }
    
    static func buildEither(first component: [T]) -> _TGroup {
        _TGroup(component)
    }
    
    static func buildEither(second component: [T]) -> _TGroup {
        _TGroup(component)
    }
    
    static func buildBlock(_ components: _TGroup...) -> [T] {
        Array(components.map(\.transitions).joined())
    }
}
