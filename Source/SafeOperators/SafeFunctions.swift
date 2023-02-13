////
////  SafeFunctions.swift
////  FiniteStateMachine
////
////  Created by Daniel Segall on 01/02/2023.
////
//
//import Foundation
//
//func joinGivenToWhen<S: SP, E: EP> (
//    _ given: Given<S, E>,
//    _ when: When<E>
//) -> [GivenWhen<S, E>] {
//    given.states.reduce(into: [GivenWhen]()) { gws, state in
//        when.events.forEach {
//            gws.append(
//                GivenWhen(given: state,
//                          when: $0,
//                          modifiers: given.modifiers,
//                          file: given.file,
//                          line: given.line)
//            )
//        }
//    }
//}
//
//func joinGivenToWhensThens<S: SP, E: EP> (
//    _ given: Given<S, E>,
//    _ whenThens: [[WhensThen<S, E >]]
//) -> [GivenWhensThen<S, E>] {
//    given.states.reduce(into: [GivenWhensThen]()) { gwts, state in
//        whenThens.flatten.forEach {
//            gwts.append(
//                GivenWhensThen(given: state,
//                              when: $0.when,
//                              then: $0.then,
//                              modifiers: given.modifiers,
//                              file: given.file,
//                              line: given.line))
//        }
//    }
//}
//
//func joinGivenWhensToThen<S: SP, E: EP> (
//    _ givenWhens: [GivenWhen<S, E>],
//    _ then: Then<S>
//) -> [GivenWhensThen<S, E>] {
//    givenWhens.reduce(into: [GivenWhensThen]()) { gwts, gw in
//        gwts.append(
//            GivenWhensThen(given: gw.given,
//                          when: gw.when,
//                          then: then.state,
//                          modifiers: gw.modifiers,
//                          file: gw.file,
//                          line: gw.line)
//        )
//    }
//}
//
//func joinWhenToThen<S: SP, E: EP> (
//    _ when: When<E>,
//    _ then: Then<S>
//) -> [WhensThen<S, E>] {
//    when.events.reduce(into: [WhensThen]()) {
//        $0.append(WhensThen(when: $1,
//                           then: then.state))
//    }
//}
//
//func joinWhensThensToAction<S: SP, E: EP> (
//    _ whenThens: [WhensThen<S, E>],
//    _ actions: [() -> ()]
//) -> [WhensThenActions<S, E>] {
//    whenThens.reduce(into: [WhensThenActions]()) {
//        $0.append(WhensThenActions(when: $1.when,
//                                 then: $1.then,
//                                 actions: actions))
//    }
//}
//
//func makeTransitions<S: SP, E: EP> (
//    _ gwts: [GivenWhensThen<S, E>],
//    _ actions: [() -> ()]
//) -> TableRow<S, E> {
//    let transitions = gwts.reduce(into: [Transition<S, E>]()) { ts, gwt in
//        ts.append(
//            Transition(givenState: gwt.given,
//                       event: gwt.when,
//                       nextState: gwt.then,
//                       actions: actions,
//                       file: gwt.file,
//                       line: gwt.line))
//    }
//    return TableRow(transitions: transitions,
//                    modifiers: gwts.first?.modifiers ?? .none)
//}
//
//func makeTransitions<S: SP, E: EP> (
//    _ given: Given<S, E>,
//    _ wtas: [[WhensThenActions<S, E>]]
//) -> TableRow<S, E> {
//    TableRow(transitions: given.formTransitions(with: wtas.flatten),
//             modifiers: given.modifiers)
//}
