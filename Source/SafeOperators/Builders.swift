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

@resultBuilder
struct TransitionBuilder<State: SP, Event: EP> {
    typealias G = TGroup<State, Event>
    
    static func buildBlock(_ ts: G...) -> G {
        let transitions = ts.reduce(into: [Transition<State, Event>]()) {
            $0.append(contentsOf: $1.transitions)
        }
        return TGroup(transitions)
    }
    
    static func buildOptional(_ t: G?) -> G {
        return t ?? TGroup([])
    }
    
    static func buildEither(first component: G) -> G {
        component
    }
    
    static func buildEither(second component: G) -> G {
        component
    }
}
