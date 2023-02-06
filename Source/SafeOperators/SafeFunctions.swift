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
    given.states.reduce(into: [GivenWhen]()) { gws, state in
        when.events.forEach {
            gws.append(
                GivenWhen(given: state,
                          when: $0,
                          superStates: given.superStates,
                          entryActions: given.entryActions,
                          exitActions: given.exitActions,
                          file: given.file,
                          line: given.line)
            )
        }
    }
}

func joinGivenToWhenThens<S: SP, E: EP> (
    _ given: Given<S, E>,
    _ whenThens: [[WhenThen<S, E >]]
) -> [GivenWhenThen<S, E>] {
    given.states.reduce(into: [GivenWhenThen]()) { gwts, state in
        whenThens.flatMap { $0 }.forEach {
            gwts.append(
                GivenWhenThen(given: state,
                              when: $0.when,
                              then: $0.then,
                              superStates: given.superStates,
                              entryActions: given.entryActions,
                              exitActions: given.exitActions,
                              file: given.file,
                              line: given.line))
        }
    }
}

func joinGivenWhensToThen<S: SP, E: EP> (
    _ givenWhens: [GivenWhen<S, E>],
    _ then: Then<S>
) -> [GivenWhenThen<S, E>] {
    givenWhens.reduce(into: [GivenWhenThen]()) { gwts, gw in
        gwts.append(
            GivenWhenThen(given: gw.given,
                          when: gw.when,
                          then: then.state,
                          superStates: gw.superStates,
                          entryActions: gw.entryActions,
                          exitActions: gw.exitActions,
                          file: gw.file,
                          line: gw.line)
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
) -> FSMTableRow<S, E> {
    var alreadyAdded = [GivenWhenThen<S, E>]()
    let transitions = givenWhenThens.reduce(into: [Transition<S, E>]()) { ts, gwt in
        func t(_ g: S, _ w: E, _ t: S, _ a: [() -> ()]) -> Transition<S, E> {
            Transition(givenState: g, event: w, nextState: t, actions: a,
                       file: gwt.file, line: gwt.line)
        }
        
        if !alreadyAdded.map(\.given).contains(gwt.given) {
            ts.append(contentsOf: gwt.allSuperWTAs.reduce(
                into: [Transition]()) {
                    $0.append(t(gwt.given, $1.when, $1.then, actions))
                }
            )
            alreadyAdded.append(gwt)
        }
        
        ts.append(t(gwt.given, gwt.when, gwt.then, actions))
    }
    let entryActions = givenWhenThens.map { $0.entryActions }.flatMap { $0 }
    let exitActions = givenWhenThens.map { $0.exitActions }.flatMap { $0 }
    return FSMTableRow(transitions,
                       entryActions: entryActions,
                       exitActions: exitActions)
}

func makeTransitions<S: SP, E: EP> (
    _ given: Given<S, E>,
    _ wtas: [[WhenThenAction<S, E>]]
) -> FSMTableRow<S, E> {
    FSMTableRow(given.formFinalTransitions(with: wtas.flatMap { $0 }),
                entryActions: given.entryActions,
                exitActions: given.exitActions)
}
