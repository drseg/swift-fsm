//
//  SafeFunctions.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

func joinGivenToWhen<S: SP, E: EP> (
    _ given: Given<S, E>,
    _ when: When<E>
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

func joinGivenToWhenThens<S: SP, E: EP> (
    _ given: Given<S, E>,
    _ whenThens: [[WhenThen<S, E >]]
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

func joinGivenWhensToThen<S: SP, E: EP> (
    _ givenWhens: [GivenWhen<S, E>],
    _ then: Then<S>
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

func joinWhenToThen<S: SP, E: EP> (
    _ when: When<E>,
    _ then: Then<S>
) -> [WhenThen<S, E>] {
    when.events.reduce(into: [WhenThen]()) {
        $0.append(WhenThen(when: $1,
                           then: then.state))
    }
}

func joinWhenThensToAction<S: SP, E: EP> (
    _ whenThens: [WhenThen<S, E>],
    _ actions: [() -> ()]
) -> [WhenThenAction<S, E>] {
    whenThens.reduce(into: [WhenThenAction]()) {
        $0.append(WhenThenAction(when: $1.when,
                                 then: $1.then,
                                 actions: actions))
    }
}

func makeTransitions<S: SP, E: EP> (
    _ givenWhenThens: [GivenWhenThen<S, E>],
    _ actions: [() -> ()]
) -> [Transition<S, E>] {
    var alreadyAdded = [GivenWhenThen<S, E>]()
    
    return givenWhenThens.reduce(into: [Transition]()) { t1, gwt in
        if
            let superState = gwt.superState,
            !alreadyAdded.contains(where: { $0.given == gwt.given })
        {
            t1.append(
                contentsOf: superState.wtas.reduce(
                    into: [Transition]()) { t2, wta in
                        t2.append(Transition(givenState: gwt.given,
                                             event: wta.when,
                                             nextState: wta.then,
                                             actions: actions))
                    })
            alreadyAdded.append(gwt)
        }
        
        t1.append(Transition(givenState: gwt.given,
                             event: gwt.when,
                             nextState: gwt.then,
                             actions: actions))
        
    }
}

func makeTransitions<S: SP, E: EP> (
    _ given: Given<S, E>,
    _ whenThenActions: [[WhenThenAction<S, E>]]
) -> [Transition<S, E>] {
    given.formTransitions(with: whenThenActions.flatMap { $0 })
}