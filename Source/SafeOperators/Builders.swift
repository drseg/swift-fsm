//
//  Builders.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 05/02/2023.
//

import Foundation

@resultBuilder
struct WTABuilder<State: SP, Event: EP> {
    static func buildBlock<Event>(
        _ wtas: [WhenThenAction<State, Event>]...
    ) -> [WhenThenAction<State, Event>] {
        wtas.flatMap { $0 }
    }
}

@resultBuilder
struct WTBuilder<State: SP, Event: EP> {
    static func buildBlock(
        _ wts: [WhenThen<State, Event>]...
    ) -> [WhenThen<State, Event>] {
        wts.flatMap { $0 }
    }
}

@resultBuilder struct TransitionBuilder<S: SP, E: EP> {
    struct TGroup: TransitionGroup, Equatable {
        typealias State = S
        typealias Event = E
        
        let transitions: [Transition<S, E>]
        
        init(_ transitions: [Transition<S, E>]) {
            self.transitions = transitions
        }
    }
    
    static func buildExpression(_ expression: [Transition<S, E>]) -> TGroup {
        TGroup(expression)
    }
    
    static func buildExpression<T: TransitionGroup>(
        _ expression: T
    ) -> TGroup where T.State == S, T.Event == E {
        TGroup(expression.transitions)
    }
    
    static func buildIf(_ components: [Transition<S, E>]?) -> TGroup {
        TGroup(components ?? [])
    }
    
    static func buildEither(first component: [Transition<S, E>]) -> TGroup {
        TGroup(component)
    }
    
    static func buildEither(second component: [Transition<S, E>]) -> TGroup {
        TGroup(component)
    }
    
    static func buildBlock(_ components: TGroup...) -> [Transition<S, E>] {
        Array(components.map(\.transitions).joined())
    }
}
