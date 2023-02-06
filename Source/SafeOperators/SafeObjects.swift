//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct SuperState<S: SP, E: EP> {
    let wtas: [WhenThenAction<S, E>]
    
    init(@WTABuilder<S, E> _ content: () -> [WhenThenAction<S, E>]) {
        wtas = content()
    }
}

protocol SSCollection {
    associatedtype S: StateProtocol
    associatedtype E: EventProtocol
    
    var superStates: [SuperState<S, E>]? { get }
}

extension SSCollection {
    var allSuperWTAs: [WhenThenAction<S, E>] {
        superStates?.map { $0.wtas }.flatMap { $0 } ?? []
    }
}

class _GivenBase<S: SP, E: EP>: SSCollection {
    typealias SS = SuperState<S, E>
    typealias WTA = WhenThenAction<S, E>
    typealias WT = WhenThen<S, E>
    
    let states: [S]
    let superStates: [SuperState<S, E>]?
    let file: String
    let line: Int
    
    init(
        _ states: S...,
        file: String = #file,
        line: Int = #line
    ) {
        self.states = states
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
    
    func formFinalTransitions(with wtas: [WTA]) -> [Transition<S, E>] {
        formTransitions(with: allSuperWTAs)
        + formTransitions(with: wtas)
    }
    
    func formTransitions(with wtas: [WTA]) -> [Transition<S, E>] {
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
        @WTABuilder<S, E> _ wtas: () -> [WTA]
    ) -> [Transition<S, E>] {
        formFinalTransitions(with: wtas())
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

class Given<S: SP, E: EP>: _GivenBase<S, E> {
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
    
    private func include(_ newSuperStates: [SS]) -> FinalGiven<S, E> {
        FinalGiven(states, newSuperStates + (superStates ?? []),
                   file: file, line: line)
    }
}

final class FinalGiven<S: SP, E: EP>: Given<S, E>, TransitionGroup {
    var transitions = [Transition<S, E>]()
    
    override init(
        _ states: [S],
        _ superStates: [SS]?,
        file: String,
        line: Int
    ) {
        super.init(states, superStates, file: file, line: line)
        self.transitions = formTransitions(with: allSuperWTAs)
    }
}

struct When<E: EP> {
    let events: [E]
    
    init(_ when: E...) {
        self.events = when
    }
}

struct GivenWhen<S: SP, E: EP>: SSCollection {
    let given: S
    let when: E
    
    let superStates: [SuperState<S, E>]?
    let file: String
    let line: Int
}

struct WhenThen<S: SP, E: EP> {
    let when: E
    let then: S
}

struct Then<State: SP> {
    let state: State
    
    init(_ then: State) {
        self.state = then
    }
}

struct GivenWhenThen<S: SP, E: EP>: SSCollection {
    let given: S
    let when: E
    let then: S
    
    let superStates: [SuperState<S, E>]?
    let file: String
    let line: Int
}

struct GWTCollection<S: SP, E: EP> {
    typealias T = Transition<S, E>
    typealias GWT = GivenWhenThen<S, E>
    
    let givenWhenThens: [GWT]
    
    init(_ gwts: [GWT]) {
        givenWhenThens = gwts
    }
    
    func action(_ action: @escaping () -> ()) -> [T] {
        actions(action)
    }
    
    func actions(_ actions: (() -> ())...) -> [T] {
        givenWhenThens | actions
    }
}

struct WhenThenAction<S: SP, E: EP>: Equatable {
    static func == (
        lhs: WhenThenAction<S, E>,
        rhs: WhenThenAction<S, E>
    ) -> Bool {
        lhs.when == rhs.when &&
        lhs.then == rhs.then
    }
    
    let when: E
    let then: S
    let actions: [() -> ()]
}
