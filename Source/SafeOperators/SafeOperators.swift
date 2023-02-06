//
//  SafeOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

func |<S: SP, E: EP> (
    given: Given<S, E>,
    when: When<E>
) -> [GivenWhen<S, E>] {
    joinGivenToWhen(given, when)
}

func |<S: SP, E: EP> (
    given: Given<S, E>,
    whenThens: [[WhenThen<S, E>]]
) -> [GivenWhenThen<S, E>] {
    joinGivenToWhenThens(given, whenThens)
}

func |<S: SP, E: EP> (
    givenWhens: [GivenWhen<S, E>],
    then: Then<S>
) -> [GivenWhenThen<S, E>] {
    joinGivenWhensToThen(givenWhens, then)
}

func |<S: SP, E: EP> (
    when: When<E>,
    then: Then<S>
) -> [WhenThen<S, E>] {
    joinWhenToThen(when, then)
}

func |<S: SP, E: EP> (
    whenThens: [[WhenThen<S, E>]],
    action: @escaping () -> ()
) -> [WhenThenAction<S, E>] {
    whenThens | [action]
}

func |<S: SP, E: EP> (
    whenThens: [[WhenThen<S, E>]],
    actions: [() -> ()]
) -> [WhenThenAction<S, E>] {
    whenThens.flatten | actions
}

func |<S: SP, E: EP> (
    whenThens: [WhenThen<S, E>],
    action: @escaping () -> ()
) -> [WhenThenAction<S, E>] {
    whenThens | [action]
}

func |<S: SP, E: EP> (
    whenThens: [WhenThen<S, E>],
    actions: [() -> ()]
) -> [WhenThenAction<S, E>] {
    joinWhenThensToAction(whenThens, actions)
}

func |<S: SP, E: EP> (
    givenWhenThens: [GivenWhenThen<S, E>],
    action: @escaping () -> ()
) -> FSMTableRow<S, E> {
    givenWhenThens | [action]
}

func |<S: SP, E: EP> (
    givenWhenThens: [GivenWhenThen<S, E>],
    actions: [() -> ()]
) -> FSMTableRow<S, E> {
    makeTransitions(givenWhenThens, actions)
}

func |<S: SP, E: EP> (
    given: Given<S, E>,
    whenThenActions: [[WhenThenAction<S, E>]]
) -> FSMTableRow<S, E> {
    makeTransitions(given, whenThenActions)
}
