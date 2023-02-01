//
//  SafeOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

enum Safe {
    @resultBuilder
    struct TransitionBuilder<State: StateProtocol, Event: EventProtocol> {
        static func buildBlock<Event>(
            _ wtas: [WhenThenAction<State, Event>]...
        ) -> [WhenThenAction<State, Event>] {
            wtas.flatMap { $0 }
        }
    }
    
    struct SuperState<State: StateProtocol, Event: EventProtocol> {
        let wtas: [Safe.WhenThenAction<State, Event>]
        
        init(@Safe.TransitionBuilder<State, Event> _ content: () -> [WhenThenAction<State, Event>]
        ) {
            wtas = content()
        }
    }
    
    struct Given<State: StateProtocol, Event: EventProtocol> {
        let givens: [State]
        var superState: SuperState<State, Event>?
        
        init(
            _ given: State...,
            superState: Safe.SuperState<State, Event>? = nil
        ) {
            self.givens = given
            self.superState = superState
        }
        
        func callAsFunction(
            @Safe.TransitionBuilder<State, Event> _ content: () -> [WhenThenAction<State, Event>]
        ) -> [Transition<State, Event>] {
            givens.reduce(into: [Transition]()) { ts, given in
                if let superState {
                    superState.wtas.forEach {
                        ts.append(Transition(givenState: given,
                                             event: $0.when,
                                             nextState: $0.then,
                                             action: $0.action))
                    }
                }
                
                content().forEach {
                    ts.append(Transition(givenState: given,
                                         event: $0.when,
                                         nextState: $0.then,
                                         action: $0.action))
                }
            }
        }
        
        @resultBuilder
        struct WhenThenBuilder {
            static func buildBlock<Event>(
                _ wts: [WhenThen<State, Event>]...
            ) -> [WhenThen<State, Event>] {
                wts.flatMap { $0 }
            }
        }
        
        func callAsFunction(
            @WhenThenBuilder _ content: () -> [WhenThen<State, Event>]
        ) -> GivenWhenThenCollection<State, Event> {
            let gwts = content().reduce(into: [GivenWhenThen]()) { gwts, wt in
                givens.forEach {
                    gwts.append(GivenWhenThen(given: $0,
                                              when: wt.when,
                                              then: wt.then,
                                              superState: superState))
                }
            }
            return GivenWhenThenCollection(givenWhenThens: gwts)
        }
        
        struct GivenWhenThenCollection<State: StateProtocol, Event: EventProtocol> {
            let givenWhenThens: [GivenWhenThen<State, Event>]
            
            func action(
                _ action: @escaping () -> Void
            ) -> [Transition<State, Event>] {
                givenWhenThens.reduce(into: [Transition]()) {
                    $0.append(Transition(givenState: $1.given,
                                         event: $1.when,
                                         nextState: $1.then,
                                         action: action))
                }
            }
        }
    }
    
    struct When<Event: EventProtocol> {
        let whens: [Event]
        
        init(_ when: Event...) {
            self.whens = when
        }
    }
    
    struct GivenWhen<State: StateProtocol, Event: EventProtocol> {
        let given: State
        let when: Event
        
        let superState: SuperState<State, Event>?
    }

    struct WhenThen<State: StateProtocol, Event: EventProtocol> {
        let when: Event
        let then: State
    }
    
    struct Then<State: StateProtocol> {
        let then: State
        
        init(_ then: State) {
            self.then = then
        }
    }
    
    struct GivenWhenThen<State: StateProtocol, Event: EventProtocol> {
        let given: State
        let when: Event
        let then: State
        
        let superState: SuperState<State, Event>?
    }
    
    struct WhenThenAction<State: StateProtocol, Event: EventProtocol>: Equatable {
        static func == (
            lhs: Safe.WhenThenAction<State, Event>,
            rhs: Safe.WhenThenAction<State, Event>
        ) -> Bool {
            lhs.when == rhs.when &&
            lhs.then == rhs.then
        }
        
        let when: Event
        let then: State
        let action: () -> Void
        
        var superState: SuperState<State, Event>?
    }
    
    struct Action {
        let action: () -> Void
        
        init(_ action: @escaping () -> Void) {
            self.action = action
        }
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: Safe.Given<State, Event>,
    rhs: Safe.When<Event>
) -> [Safe.GivenWhen<State, Event>] {
    lhs.givens.reduce(into: [Safe.GivenWhen]()) { givenWhens, given in
        rhs.whens.forEach {
            givenWhens.append(
                Safe.GivenWhen(given: given,
                               when: $0,
                               superState: lhs.superState)
            )
        }
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: Safe.Given<State, Event>,
    rhs: [[Safe.WhenThen<State, Event >]]
) -> [Safe.GivenWhenThen<State, Event>] {
    lhs.givens.reduce(into: [Safe.GivenWhenThen]()) { givenWhenThens, given in
        rhs.flatMap { $0 }.forEach {
            givenWhenThens
                .append(Safe.GivenWhenThen(given: given,
                                           when: $0.when,
                                           then: $0.then,
                                           superState: lhs.superState))
        }
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [Safe.GivenWhen<State, Event>],
    rhs: Safe.Then<State>
) -> [Safe.GivenWhenThen<State, Event>] {
    lhs.reduce(into: [Safe.GivenWhenThen]()) { givenWhenThens, givenWhen in
        givenWhenThens.append(
            Safe.GivenWhenThen(given: givenWhen.given,
                               when: givenWhen.when,
                               then: rhs.then,
                               superState: givenWhen.superState)
        )
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [Safe.GivenWhenThen<State, Event>],
    rhs: Safe.Action
) -> [Transition<State,Event>] {
    lhs | rhs.action
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [Safe.GivenWhenThen<State, Event>],
    rhs: @escaping () -> Void
) -> [Transition<State, Event>] {
    lhs.reduce(into: [Transition]()) {
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

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: Safe.When<Event>,
    rhs: Safe.Then<State>
) -> [Safe.WhenThen<State, Event>] {
    lhs.whens.reduce(into: [Safe.WhenThen]()) { whenThens, when in
        whenThens.append(
            Safe.WhenThen(when: when,
                          then: rhs.then))
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [[Safe.WhenThen<State, Event>]],
    rhs: Safe.Action
) -> [Safe.WhenThenAction<State, Event>] {
    lhs.flatMap { $0 } | rhs
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [Safe.WhenThen<State, Event>],
    rhs: Safe.Action
) -> [Safe.WhenThenAction<State, Event>] {
    lhs | rhs.action
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [[Safe.WhenThen<State, Event>]],
    rhs: @escaping () -> Void
) -> [Safe.WhenThenAction<State, Event>] {
    lhs.flatMap { $0 } | rhs
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: [Safe.WhenThen<State, Event>],
    rhs: @escaping () -> Void
) -> [Safe.WhenThenAction<State, Event>] {
    lhs.reduce(into: [Safe.WhenThenAction]()) {
        $0.append(Safe.WhenThenAction(when: $1.when,
                                      then: $1.then,
                                      action: rhs))
    }
}

func |<State: StateProtocol, Event: EventProtocol> (
    lhs: Safe.Given<State, Event>,
    rhs: [[Safe.WhenThenAction<State, Event>]]
) -> [Transition<State, Event>] {
    rhs.flatMap { $0 }.reduce(into: [Transition]()) { ts, action in
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
    
    // SuperState in here
}
