//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct SuperState<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    
    let wtas: [WhenThenAction<S, E>]
    
    init(@WTABuilder<S, E> _ content: () -> [WhenThenAction<S, E>]) {
        wtas = content()
    }
}

final class FinalGiven<S: SP, E: EP>: Given<S, E>, TransitionGroup {
    var transitions = [Transition<S, E>]()
    
    override init(
        _ given: [S],
        _ superState: SuperState<S, E>?,
        file: String,
        line: Int
    ) {
        super.init(given, superState, file: file, line: line)
        self.transitions = formTransitions(with: superState?.wtas ?? [])
    }
}

class Given<State: SP, Event: EP> {
    typealias S = State
    typealias E = Event
    typealias WTA = WhenThenAction<State, Event>
    
    let states: [S]
    let superState: SuperState<S, E>?
    let file: String
    let line: Int
    
    init(
        _ given: S...,
        file: String = #file,
        line: Int = #line
    ) {
        self.states = given
        self.superState = nil
        self.file = file
        self.line = line
    }
    
    fileprivate init(
        _ given: [S],
        _ superState: SuperState<S, E>?,
        file: String,
        line: Int
    ) {
        self.states = given
        self.superState = superState
        self.file = file
        self.line = line
    }
    
    func include(_ superState: SuperState<S, E>) -> FinalGiven<State, Event> {
        FinalGiven(states, superState, file: file, line: line)
    }
    
    func include(
        _ superState: SuperState<S, E>,
        @WTABuilder<S, E> wtas: () -> [WTA]
    ) -> TGroup<S, E> {
        include(superState).callAsFunction(wtas)
    }
    
    func callAsFunction(
        @WTABuilder<S, E> _ wtas: () -> [WTA]
    ) -> TGroup<S, E> {
        formTransitionsTGroup(with: wtas())
    }
    
    func formTransitionsTGroup(with wtas: [WTA]) -> TGroup<S, E> {
        TGroup(formTransitions(with: superState?.wtas ?? [])
               + formTransitions(with: wtas))
    }
    
    fileprivate func formTransitions(with wtas: [WTA]) -> [Transition<S, E>] {
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
    
    func callAsFunction(
        @WTBuilder<S, E> _ content: () -> [WhenThen<S, E>]
    ) -> GWTCollection<S, E> {
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

struct GWTCollection<S: SP, E: EP> {
    typealias G = TGroup<S, E>
    typealias GWT = GivenWhenThen<S, E>
    
    let givenWhenThens: [GWT]
    
    init(_ gwts: [GWT]) {
        givenWhenThens = gwts
    }
    
    func action(_ action: @escaping () -> ()) -> G {
        actions(action)
    }
    
    func actions(_ actions: (() -> ())...) -> G {
        givenWhenThens | actions
    }
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
