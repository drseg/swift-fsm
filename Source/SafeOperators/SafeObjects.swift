//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct RowModifiers<S: SP, E: EP> {
    let superStates: [SuperState<S, E>]
    let entryActions: [() -> ()]
    let exitActions: [() -> ()]
    
    static var none: Self {
        RowModifiers(superStates: [], entryActions: [], exitActions: [])
    }
}

protocol Modifiable {
    associatedtype S: StateProtocol
    associatedtype E: EventProtocol
    
    var modifiers: RowModifiers<S, E> { get }
}

extension Modifiable {
    var allSuperWTAs: [WhenThenAction<S, E>] {
        modifiers.superStates.map { $0.wtas }.flatten
    }
}

struct SuperState<S: SP, E: EP> {
    let wtas: [WhenThenAction<S, E>]
    
    init(@WTABuilder<S, E> _ content: () -> [WhenThenAction<S, E>]) {
        wtas = content()
    }
}


class _GivenBase<S: SP, E: EP>: Modifiable {
    typealias SS = SuperState<S, E>
    typealias WTA = WhenThenAction<S, E>
    typealias WT = WhenThen<S, E>
    
    let states: [S]
    let modifiers: RowModifiers<S, E>
    
    let file: String
    let line: Int
    
    init(_ states: S..., file: String = #file, line: Int = #line) {
        self.states = states
        self.modifiers = .none
        self.file = file
        self.line = line
    }
    
    fileprivate init(_ s: [S], _ m: RowModifiers<S, E>, file: String, line: Int) {
        self.states = s
        self.modifiers = m
        self.file = file
        self.line = line
    }
    
    func formFinalTransitions(with wtas: [WTA]) -> [Transition<S, E>] {
        formTransitions(with: allSuperWTAs) + formTransitions(with: wtas)
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
    ) -> TableRow<S, E> {
        TableRow(transitions: formFinalTransitions(with: wtas()),
                    modifiers: modifiers)
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
                                      modifiers: modifiers,
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
    ) -> TableRow<S, E> {
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
    
    private func include(_ ss: [SS]) -> FinalGiven<S, E> {
        let modifiers = RowModifiers(superStates: modifiers.superStates + ss,
                                     entryActions: modifiers.entryActions,
                                     exitActions: modifiers.exitActions)
        return FinalGiven(states, modifiers, file: file, line: line)
    }
}

final class FinalGiven<S: SP, E: EP>: Given<S, E>, TableRowProtocol {
    var transitions = [Transition<S, E>]()
    
    override init(_ s: [S], _ m: RowModifiers<S, E>, file: String, line: Int) {
        super.init(s, m, file: file, line: line)
        self.transitions = formTransitions(with: allSuperWTAs)
    }
}

struct When<E: EP> {
    let events: [E]
    
    init(_ when: E...) {
        self.events = when
    }
}

struct GivenWhen<S: SP, E: EP>: Modifiable {
    
    let given: S
    let when: E
    
    let modifiers: RowModifiers<S, E>
    
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

struct GivenWhenThen<S: SP, E: EP>: Modifiable {
    
    let given: S
    let when: E
    let then: S
    
    let modifiers: RowModifiers<S, E>
    
    let file: String
    let line: Int
}

struct GWTCollection<S: SP, E: EP> {
    typealias GWT = GivenWhenThen<S, E>
    
    let givenWhenThens: [GWT]
    
    init(_ gwts: [GWT]) {
        givenWhenThens = gwts
    }
    
    func action(_ action: @escaping () -> ()) -> TableRow<S, E> {
        actions(action)
    }
    
    func actions(_ actions: (() -> ())...) -> TableRow<S, E> {
        givenWhenThens | actions
    }
}

struct WhenThenAction<S: SP, E: EP>: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.when == rhs.when &&
        lhs.then == rhs.then
    }
    
    let when: E
    let then: S
    let actions: [() -> ()]
}
