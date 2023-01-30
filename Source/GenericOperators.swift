//
//  GenericOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}

enum Generic {
    struct Given<State> {
        let givens: [State]
        
        init(_ given: State...) {
            self.givens = given
        }
    }
    
    struct When<Event> {
        let whens: [Event]
        
        init(_ when: Event...) {
            self.whens = when
        }
    }
    
    struct GivenWhen<State,Event> {
        let given: State
        let when: Event
    }

    struct WhenThen<Event,State> {
        let when: Event
        let then: State
    }
    
    struct Then<State> {
        let then: State
        
        init(_ then: State) {
            self.then = then
        }
    }
    
    struct GivenWhenThen<State, Event> {
        let given: State
        let when: Event
        let then: State
    }
    
    struct ThenAction<State> {
        let then: State
        let action: () -> Void
    }
    
    struct WhenThenAction<Event,State> {
        let when: Event
        let then: State
        let action: () -> Void
    }
    
    struct Action {
        let action: () -> Void
        
        init(_ action: @escaping () -> Void) {
            self.action = action
        }
    }
}

func |<State, Event> (
    lhs: Generic.Given<State>,
    rhs: Generic.When<Event>
) -> [Generic.GivenWhen<State, Event>] {
    lhs.givens.reduce(into: [Generic.GivenWhen]()) { givenWhens, given in
        rhs.whens.forEach {
            givenWhens.append(Generic.GivenWhen(given: given, when: $0))
        }
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: State,
    rhs: Event
) -> Generic.GivenWhen<State, Event> {
    Generic.GivenWhen(given: lhs, when: rhs)
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [State],
    rhs: Event
) -> [Generic.GivenWhen<State, Event>] {
    lhs.reduce(into: [Generic.GivenWhen<State, Event>]()) {
        $0.append($1 | rhs)
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: State,
    rhs: [Event]
) -> [Generic.GivenWhen<State, Event>] {
    rhs.reduce(into: [Generic.GivenWhen<State, Event>]()) {
        $0.append(lhs | $1)
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: State,
    rhs: [Generic.WhenThen<Event, State>]
) -> [Generic.GivenWhenThen<State, Event>] {
    rhs.reduce(into: [Generic.GivenWhenThen<State, Event>]()) {
        $0.append(Generic.GivenWhenThen(given: lhs, when: $1.when, then: $1.then))
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [State],
    rhs: [Event]
) -> [Generic.GivenWhen<State, Event>] {
    rhs.reduce(into: [Generic.GivenWhen<State, Event>]()) {
        $0.append(contentsOf: lhs | $1)
    }
}

func |<State: StateProtocol, Event: Equatable> (
    lhs: State,
    rhs: [Generic.WhenThenAction<Event, State>]
) -> [Transition<State, Event>] {
    rhs.reduce(into: [Transition<State, Event>]()) {
        $0.append(
            Transition(givenState: lhs,
                       event: $1.when,
                       nextState: $1.then,
                       action: $1.action)
        )
    }
}

func |<State: StateProtocol, Event: Equatable> (
    lhs: [State],
    rhs: [Generic.WhenThenAction<Event, State>]
) -> [Transition<State, Event>] {
    rhs.reduce(into: [Transition<State, Event>]()) { wtas, wta in
        lhs.forEach {
            wtas.append(
                Transition(givenState: $0,
                           event: wta.when,
                           nextState: wta.then,
                           action: wta.action)
            )
        }
    }
}

func |<Event: EventProtocol, State: StateProtocol> (
    lhs: [Event],
    rhs: State
) -> [Generic.WhenThen<Event, State>] {
    lhs.reduce(into: [Generic.WhenThen<Event, State>]()) {
        $0.append(
            Generic.WhenThen(when: $1, then: rhs)
        )
    }
}

func |<Event: EventProtocol, State: StateProtocol> (
    lhs: Event,
    rhs: State
) -> Generic.WhenThen<Event, State> {
    Generic.WhenThen(when: lhs,
                     then: rhs)
}


func |<State: Equatable, Event: Equatable> (
    lhs: Generic.WhenThen<State, Event>,
    rhs: @escaping () -> Void
) -> Generic.WhenThenAction<State, Event> {
    Generic.WhenThenAction(when: lhs.when, then: lhs.then, action: rhs)
}

func |<State: Equatable, Event: Equatable> (
    lhs: Generic.GivenWhen<State, Event>,
    rhs: State
) -> Generic.GivenWhenThen<State, Event> {
    Generic.GivenWhenThen(given: lhs.given, when: lhs.when, then: rhs)
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Generic.GivenWhen<State, Event>],
    rhs: State
) -> [Generic.GivenWhenThen<State, Event>] {
    lhs.reduce(into: [Generic.GivenWhenThen<State, Event>]()) {
        $0.append(Generic.GivenWhenThen(given: $1.given,
                                        when: $1.when,
                                        then: rhs))
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: Generic.Given<State>,
    rhs: [[Generic.WhenThen<Event,State>]]
) -> [Generic.GivenWhenThen<State,Event>] {
    lhs.givens.reduce(into: [Generic.GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens
                .append(Generic.GivenWhenThen(given: given,
                                              when: $0.when,
                                              then: $0.then))
        }
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Generic.GivenWhen<State, Event>],
    rhs: Generic.Then<State>
) -> [Generic.GivenWhenThen<State,Event>] {
    lhs.reduce(into: [Generic.GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(Generic.GivenWhenThen(given: givenWhen.given,
                                            when: givenWhen.when,
                                            then: rhs.then))
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Generic.GivenWhenThen<State,Event>],
    rhs: Generic.Action
) -> [Transition<State,Event>] {
    lhs | rhs.action
}

func |<State: Equatable, Event: Equatable> (
    lhs: Generic.GivenWhenThen<State,Event>,
    rhs: @escaping () -> Void
) -> [Transition<State,Event>] {
    [Transition(
        givenState: lhs.given,
        event: lhs.when,
        nextState: lhs.then,
        action: rhs
    )]
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Generic.GivenWhenThen<State,Event>],
    rhs: @escaping () -> Void
) -> [Transition<State,Event>] {
    lhs.reduce(into: [Transition<State,Event>]()) {
        $0.append(
            Transition(
                givenState: $1.given,
                event: $1.when,
                nextState: $1.then,
                action: rhs
            )
        )
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: Generic.When<Event>,
    rhs: Generic.Then<State>
) -> [Generic.WhenThen<Event,State>] {
    lhs.whens.reduce(into: [Generic.WhenThen<Event,State>]()) { whenThens, when in
        whenThens.append(Generic.WhenThen(when: when, then: rhs.then))
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: [Generic.WhenThen<Event,State>],
    rhs: Generic.Action
) -> [Generic.WhenThenAction<Event,State>] {
    lhs.reduce(into: [Generic.WhenThenAction<Event,State>]()) {
        $0.append(Generic.WhenThenAction(when: $1.when,
                                         then: $1.then,
                                         action: rhs.action))
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: [Generic.WhenThen<Event,State>],
    rhs: @escaping () -> ()
) -> [Generic.WhenThenAction<Event,State>] {
    lhs.reduce(into: [Generic.WhenThenAction<Event,State>]()) {
        $0.append(Generic.WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs))
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: [[Generic.WhenThen<Event,State>]],
    rhs: Generic.Action
) -> [Generic.WhenThenAction<Event,State>] {
    lhs.flatMap { $0 }.reduce(into: [Generic.WhenThenAction<Event,State>]()) {
        $0.append(Generic.WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: Generic.Given<State>,
    rhs: [[Generic.WhenThenAction<Event,State>]]
) -> [Transition<State,Event>] {
    rhs.flatMap { $0 }.reduce(into: [Transition<State,Event>]()) { ts, action in
        lhs.givens.forEach { given in
            ts.append(
                Transition(
                    givenState: given,
                    event: action.when,
                    nextState: action.then,
                    action: action.action
                )
            )
        }
    }
}
