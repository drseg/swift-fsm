//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

@resultBuilder
struct TransitionBuilder<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    static func buildBlock<E>(
        _ wtas: [WhenThenAction<S, E>]...
    ) -> [WhenThenAction<S, E>] {
        wtas.flatMap { $0 }
    }
}

struct SuperState<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    let wtas: [WhenThenAction<S, E>]
    
    init(@TransitionBuilder<S, E> _ content: () -> [WhenThenAction<S, E>]) {
        wtas = content()
    }
}

struct Given<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    let states: [S]
    var superState: SuperState<S, E>?
    
    init(
        _ given: S...,
        superState: SuperState<S, E>? = nil
    ) {
        self.states = given
        self.superState = superState
    }
    
    func callAsFunction(
        @TransitionBuilder<S, E> _ content: () -> [WhenThenAction<S, E>]
    ) -> [Transition<S, E>] {
        formTransitions(with: content())
    }
    
    func formTransitions(
        with wtas: [WhenThenAction<S, E>]
    ) -> [Transition<S, E>] {
        states.reduce(into: [Transition]()) { ts, given in
            if let superState {
                superState.wtas.forEach {
                    ts.append(Transition(givenState: given,
                                         event: $0.when,
                                         nextState: $0.then,
                                         action: $0.action))
                }
            }
            
            wtas.forEach {
                ts.append(Transition(givenState: given,
                                     event: $0.when,
                                     nextState: $0.then,
                                     action: $0.action))
            }
        }
    }
    
    @resultBuilder
    struct WhenThenBuilder {
        static func buildBlock(
            _ wts: [WhenThen<S, E>]...
        ) -> [WhenThen<S, E>] {
            wts.flatMap { $0 }
        }
    }
    
    func callAsFunction(
        @WhenThenBuilder _ content: () -> [WhenThen<S, E>]
    ) -> GivenWhenThenCollection {
        GivenWhenThenCollection(
            content().reduce(into: [GivenWhenThen]()) { gwts, wt in
                states.forEach {
                    gwts.append(
                        GivenWhenThen(given: $0,
                                      when: wt.when,
                                      then: wt.then,
                                      superState: superState))
                }
            }
        )
    }
    
    struct GivenWhenThenCollection {
        let givenWhenThens: [GivenWhenThen<S, E>]
        
        init(_ gwts: [GivenWhenThen<S, E>]) {
            givenWhenThens = gwts
        }
        
        func action(
            _ action: @escaping () -> Void
        ) -> [Transition<S, E>] {
            givenWhenThens | action
        }
    }
}

struct When<Event: EP> {
    let events: [Event]
    
    init(_ when: Event...) {
        self.events = when
    }
}

struct GivenWhen<State: SP, Event: EP> {
    let given: State
    let when: Event
    
    let superState: SuperState<State, Event>?
}

struct WhenThen<State: SP, Event: EP> {
    let when: Event
    let then: State
}

struct Then<State: SP> {
    let state: State
    
    init(_ then: State) {
        self.state = then
    }
}

struct GivenWhenThen<State: SP, Event: EP> {
    let given: State
    let when: Event
    let then: State
    
    let superState: SuperState<State, Event>?
}

struct WhenThenAction<State: SP, Event: EP>: Equatable {
    static func == (
        lhs: WhenThenAction<State, Event>,
        rhs: WhenThenAction<State, Event>
    ) -> Bool {
        lhs.when == rhs.when &&
        lhs.then == rhs.then
    }
    
    let when: Event
    let then: State
    let action: () -> Void
}
