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

protocol HoldsSuperStates {
    associatedtype S: StateProtocol
    associatedtype E: EventProtocol
    
    var superStates: [SuperState<S, E>]? { get }
}

extension HoldsSuperStates {
    var allSuperWTAs: [WhenThenAction<S, E>] {
        superStates?.map { $0.wtas }.flatMap { $0 } ?? []
    }
}

final class FinalGiven<S: SP, E: EP>: Given<S, E>, TransitionGroup {
    var transitions = [Transition<S, E>]()
    
    override init(
        _ given: [S],
        _ superStates: [SS]?,
        file: String,
        line: Int
    ) {
        super.init(given, superStates, file: file, line: line)
        self.transitions = formTransitions(with: allSuperWTAs)
    }
}

class Given<State: SP, Event: EP>: HoldsSuperStates {
    typealias S = State
    typealias E = Event
    typealias SS = SuperState<S, E>
    typealias WTA = WhenThenAction<S, E>
    typealias WT = WhenThen<S, E>
    
    let states: [S]
    let superStates: [SuperState<S, E>]?
    let file: String
    let line: Int
    
    init(
        _ given: S...,
        file: String = #file,
        line: Int = #line
    ) {
        self.states = given
        self.superStates = nil
        self.file = file
        self.line = line
    }
    
    fileprivate init(
        _ given: [S],
        _ superStates: [SS]?,
        file: String,
        line: Int
    ) {
        self.states = given
        self.superStates = superStates
        self.file = file
        self.line = line
    }
    
    func include(
        _ superStates: SS...,
        @WTABuilder<S, E> wtas: () -> [WTA]
    ) -> [Transition<S, E>] {
        include(superStates).callAsFunction(wtas)
    }
    
    func include(
        _ superStates: SS...,
        @WTBuilder<S, E> wts: () -> [WT]
    ) -> GWTCollection<S, E> {
        include(superStates).callAsFunction(wts)
    }
    
    func include(_ superStates: SS...) -> FinalGiven<S, E> {
        include(superStates)
    }
    
    private func include(_ superStates: [SS]) -> FinalGiven<S, E> {
        FinalGiven(states, superStates, file: file, line: line)
    }
    
    func callAsFunction(
        @WTABuilder<S, E> _ wtas: () -> [WTA]
    ) -> [Transition<S, E>] {
        formFinalTransitions(with: wtas())
    }
    
    func formFinalTransitions(with wtas: [WTA]) -> [Transition<S, E>] {
        formTransitions(with: allSuperWTAs)
        + formTransitions(with: wtas)
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
        @WTBuilder<S, E> _ content: () -> [WT]
    ) -> GWTCollection<S, E> {
        GWTCollection(
            content().reduce(into: [GivenWhenThen]()) { gwts, wt in
                states.forEach {
                    gwts.append(
                        GivenWhenThen(given: $0,
                                      when: wt.when,
                                      then: wt.then,
                                      superStates: superStates,
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

struct GivenWhen<State: SP, Event: EP>: HoldsSuperStates {
    let given: State
    let when: Event
    
    let superStates: [SuperState<State, Event>]?
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

struct GivenWhenThen<State: SP, Event: EP>: HoldsSuperStates {
    let given: State
    let when: Event
    let then: State
    
    let superStates: [SuperState<State, Event>]?
    let file: String
    let line: Int
}

struct GWTCollection<S: SP, E: EP> {
    typealias G = [Transition<S, E>]
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
