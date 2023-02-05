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
    struct Output: TransitionGroup, Equatable {
        var transitions: [Transition<S, E>]
        
        init(_ transitions: [Transition<S, E>]) {
            self.transitions = transitions
        }

        typealias State = S
        typealias Event = E
    }

    static func buildExpression<T: TransitionGroup>(
        _ expression: T
    ) -> Output where T.State == S, T.Event == E {
        Output(expression.transitions)
    }

    static func buildBlock(_ components: Output...) -> Output {
        var first = components.first!
        components.dropFirst().forEach {
            first.transitions.append(contentsOf: $0.transitions)
        }
        return first
    }

    static func buildIf(_ components: Output?) -> Output {
        components ?? Output([])
    }

    static func buildEither(first component: Output) -> Output {
        component
    }

    static func buildEither(second component: Output) -> Output {
        component
    }
}
