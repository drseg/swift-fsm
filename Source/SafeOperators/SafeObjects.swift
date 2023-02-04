//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

@resultBuilder
struct WTABuilder<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    static func buildBlock<E>(
        _ wtas: [WhenThenAction<S, E>]...
    ) -> [WhenThenAction<S, E>] {
        wtas.flatMap { $0 }
    }
}

final class FinalTransitions<State, Event>: Transition<State, Event>.Group
where State: StateProtocol, Event: EventProtocol { }

struct SuperState<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    let wtas: [WhenThenAction<S, E>]
    
    init(@WTABuilder<S, E> _ content: () -> [WhenThenAction<S, E>]) {
        wtas = content()
    }
}

final class Given<State: SP, Event: EP>: Transition<State, Event>.Group {
    typealias S = State
    typealias E = Event
    
    let states: [S]
    var superState: SuperState<S, E>?
    let file: String
    let line: Int
    
    init(
        _ given: S...,
        implements superState: SuperState<S, E>? = nil,
        file: String = #file,
        line: Int = #line
    ) {
        self.states = given
        self.superState = superState
        self.file = file
        self.line = line
        
        super.init()
        
        if let superState {
            transitions = formTransitions(with: superState.wtas)
        }
    }
    
    func callAsFunction(
        @WTABuilder<S, E> _ wtas: () -> [WhenThenAction<S, E>]
    ) -> FinalTransitions<S, E> {
        formFinalTransitions(with: wtas())
    }
    
    func formFinalTransitions(
        with wtas: [WhenThenAction<S, E>]
    ) -> FinalTransitions<S, E> {
        FinalTransitions(transitions + formTransitions(with: wtas))
    }
    
    func formTransitions(
        with wtas: [WhenThenAction<S, E>]
    ) -> [Transition<S, E>] {
        states.reduce(into: [Transition]()) { ts, given in
            wtas.forEach {
                ts.append(Transition(givenState: given,
                                     event: $0.when,
                                     nextState: $0.then,
                                     actions: $0.actions,
                                     file: file,
                                     line: line))
            }
        }
    }
    
    @resultBuilder
    struct WTBuilder {
        static func buildBlock(
            _ wts: [WhenThen<S, E>]...
        ) -> [WhenThen<S, E>] {
            wts.flatMap { $0 }
        }
    }
    
    func callAsFunction(
        @WTBuilder _ content: () -> [WhenThen<S, E>]
    ) -> GWTCollection {
        GWTCollection(
            content().reduce(into: [GivenWhenThen]()) { gwts, wt in
                states.forEach {
                    gwts.append(
                        GivenWhenThen(given: $0,
                                      when: wt.when,
                                      then: wt.then,
                                      superState: superState,
                                      file: file,
                                      line: line))
                }
            }
        ) 
    }
    
    struct GWTCollection {
        let givenWhenThens: [GivenWhenThen<S, E>]
        
        init(_ gwts: [GivenWhenThen<S, E>]) {
            givenWhenThens = gwts
        }
        
        func action(
            _ action: @escaping () -> ()
        ) -> FinalTransitions<S, E> {
            actions(action)
        }
        
        func actions(
            _ actions: (() -> ())...
        ) -> FinalTransitions<S, E> {
            givenWhenThens | actions
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
    let file: String
    let line: Int
    
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
    let file: String
    let line: Int
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
    let actions: [() -> ()]
}
