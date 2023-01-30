//
//  GenericOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

enum Safe {
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
    lhs: Safe.Given<State>,
    rhs: Safe.When<Event>
) -> [Safe.GivenWhen<State, Event>] {
    lhs.givens.reduce(into: [Safe.GivenWhen]()) { givenWhens, given in
        rhs.whens.forEach {
            givenWhens.append(Safe.GivenWhen(given: given, when: $0))
        }
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: Safe.Given<State>,
    rhs: [[Safe.WhenThen<Event,State>]]
) -> [Safe.GivenWhenThen<State,Event>] {
    lhs.givens.reduce(into: [Safe.GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens
                .append(Safe.GivenWhenThen(given: given,
                                              when: $0.when,
                                              then: $0.then))
        }
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Safe.GivenWhen<State, Event>],
    rhs: Safe.Then<State>
) -> [Safe.GivenWhenThen<State,Event>] {
    lhs.reduce(into: [Safe.GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(Safe.GivenWhenThen(given: givenWhen.given,
                                            when: givenWhen.when,
                                            then: rhs.then))
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Safe.GivenWhenThen<State,Event>],
    rhs: Safe.Action
) -> [Transition<State,Event>] {
    lhs | rhs.action
}

func |<State: Equatable, Event: Equatable> (
    lhs: [Safe.GivenWhenThen<State,Event>],
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
    lhs: Safe.When<Event>,
    rhs: Safe.Then<State>
) -> [Safe.WhenThen<Event,State>] {
    lhs.whens.reduce(into: [Safe.WhenThen<Event,State>]()) { whenThens, when in
        whenThens.append(Safe.WhenThen(when: when, then: rhs.then))
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: [Safe.WhenThen<Event,State>],
    rhs: Safe.Action
) -> [Safe.WhenThenAction<Event,State>] {
    lhs.reduce(into: [Safe.WhenThenAction<Event,State>]()) {
        $0.append(Safe.WhenThenAction(when: $1.when,
                                         then: $1.then,
                                         action: rhs.action))
    }
}

func |<Event: Equatable, State: Equatable> (
    lhs: [[Safe.WhenThen<Event,State>]],
    rhs: Safe.Action
) -> [Safe.WhenThenAction<Event,State>] {
    lhs.flatMap { $0 }.reduce(into: [Safe.WhenThenAction<Event,State>]()) {
        $0.append(Safe.WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 action: rhs.action))
    }
}

func |<State: Equatable, Event: Equatable> (
    lhs: Safe.Given<State>,
    rhs: [[Safe.WhenThenAction<Event,State>]]
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
