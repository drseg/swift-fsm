////
////  SafeOperators.swift
////  FiniteStateMachine
////
////  Created by Daniel Segall on 29/01/2023.
////
//
//import Foundation
//
//func |<S: SP, E: EP> (
//    given: Given<S, E>,
//    when: When<E>
//) -> [GivenWhen<S, E>] {
//    joinGivenToWhen(given, when)
//}
//
//func |<S: SP, E: EP> (
//    given: Given<S, E>,
//    whenThens: [[WhensThen<S, E>]]
//) -> [GivenWhensThen<S, E>] {
//    joinGivenToWhensThens(given, whenThens)
//}
//
//func |<S: SP, E: EP> (
//    givenWhens: [GivenWhen<S, E>],
//    then: Then<S>
//) -> [GivenWhensThen<S, E>] {
//    joinGivenWhensToThen(givenWhens, then)
//}
//
//func |<S: SP, E: EP> (
//    when: When<E>,
//    then: Then<S>
//) -> [WhensThen<S, E>] {
//    joinWhenToThen(when, then)
//}
//
//func |<S: SP, E: EP> (
//    whenThens: [[WhensThen<S, E>]],
//    action: @escaping () -> ()
//) -> [WhensThenActions<S, E>] {
//    whenThens | [action]
//}
//
//func |<S: SP, E: EP> (
//    whenThens: [[WhensThen<S, E>]],
//    actions: [() -> ()]
//) -> [WhensThenActions<S, E>] {
//    whenThens.flatten | actions
//}
//
//func |<S: SP, E: EP> (
//    whenThens: [WhensThen<S, E>],
//    action: @escaping () -> ()
//) -> [WhensThenActions<S, E>] {
//    whenThens | [action]
//}
//
//func |<S: SP, E: EP> (
//    whenThens: [WhensThen<S, E>],
//    actions: [() -> ()]
//) -> [WhensThenActions<S, E>] {
//    joinWhensThensToAction(whenThens, actions)
//}
//
//func |<S: SP, E: EP> (
//    givenWhensThens: [GivenWhensThen<S, E>],
//    action: @escaping () -> ()
//) -> TableRow<S, E> {
//    givenWhensThens | [action]
//}
//
//func |<S: SP, E: EP> (
//    givenWhensThens: [GivenWhensThen<S, E>],
//    actions: [() -> ()]
//) -> TableRow<S, E> {
//    makeTransitions(givenWhensThens, actions)
//}
//
//func |<S: SP, E: EP> (
//    given: Given<S, E>,
//    whenThenActions: [[WhensThenActions<S, E>]]
//) -> TableRow<S, E> {
//    makeTransitions(given, whenThenActions)
//}
//
//infix operator =>: AdditionPrecedence
