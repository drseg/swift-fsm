//
//  SafeOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

typealias SP = StateProtocol
typealias EP = EventProtocol

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
            wtas.forEach {
                ts.append(Transition(givenState: given,
                                     event: $0.when,
                                     nextState: $0.then,
                                     action: $0.action))
            }
            
            if let superState {
                superState.wtas.forEach {
                    ts.append(Transition(givenState: given,
                                         event: $0.when,
                                         nextState: $0.then,
                                         action: $0.action))
                }
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

func |<S: SP, E: EP> (
    given: Given<S, E>,
    when: When<E>
) -> [GivenWhen<S, E>] {
    given.states.reduce(into: [GivenWhen]()) { givenWhens, state in
        when.events.forEach {
            givenWhens.append(
                GivenWhen(given: state,
                          when: $0,
                          superState: given.superState)
            )
        }
    }
}

func |<S: SP, E: EP> (
    given: Given<S, E>,
    whenThens: [[WhenThen<S, E >]]
) -> [GivenWhenThen<S, E>] {
    given.states.reduce(into: [GivenWhenThen]()) { givenWhenThens, state in
        whenThens.flatMap { $0 }.forEach {
            givenWhenThens
                .append(GivenWhenThen(given: state,
                                      when: $0.when,
                                      then: $0.then,
                                      superState: given.superState))
        }
    }
}

func |<S: SP, E: EP> (
    givenWhens: [GivenWhen<S, E>],
    then: Then<S>
) -> [GivenWhenThen<S, E>] {
    givenWhens.reduce(into: [GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(
            GivenWhenThen(given: givenWhen.given,
                          when: givenWhen.when,
                          then: then.state,
                          superState: givenWhen.superState)
        )
    }
}

func |<S: SP, E: EP> (
    when: When<E>,
    then: Then<S>
) -> [WhenThen<S, E>] {
    when.events.reduce(into: [WhenThen]()) {
        $0.append(WhenThen(when: $1,
                           then: then.state))
    }
}

func |<S: SP, E: EP> (
    whenThens: [[WhenThen<S, E>]],
    action: @escaping () -> Void
) -> [WhenThenAction<S, E>] {
    whenThens.flatMap { $0 } | action
}

func |<S: SP, E: EP> (
    whenThens: [WhenThen<S, E>],
    action: @escaping () -> Void
) -> [WhenThenAction<S, E>] {
    whenThens.reduce(into: [WhenThenAction]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: action))
    }
}

func |<S: SP, E: EP> (
    givenWhenThens: [GivenWhenThen<S, E>],
    action: @escaping () -> Void
) -> [Transition<S, E>] {
    givenWhenThens.reduce(into: [Transition]()) { t1, gwt in
        t1.append(Transition(givenState: gwt.given,
                             event: gwt.when,
                             nextState: gwt.then,
                             action: action))
        
        if let superState = gwt.superState {
            t1.append(contentsOf: superState.wtas.reduce(into: [Transition]()) { t2, wta in
                t2.append(Transition(givenState: gwt.given,
                                     event: wta.when,
                                     nextState: wta.then,
                                     action: action))
            })
        }
    }
}

func |<S: SP, E: EP> (
    given: Given<S, E>,
    whenThenActions: [[WhenThenAction<S, E>]]
) -> [Transition<S, E>] {
    given.formTransitions(with: whenThenActions.flatMap { $0 })
}
