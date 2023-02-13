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
    
    init(
        superStates: [SuperState<S, E>] = [],
        entryActions: [() -> ()] = [],
        exitActions: [() -> ()] = []
    ) {
        self.superStates = superStates
        self.entryActions = entryActions
        self.exitActions = exitActions
    }
    
    static var none: Self {
        Self()
    }
}

struct SuperState<S: SP, E: EP>: Hashable {
    let wtas: [WhensThenActions<S, E>]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wtas)
    }
    
    init(@WTABuilder<S, E> _ content: () -> [any WTARowProtocol<S, E>]) {
        wtas = content().wtas()
    }
}

struct Whens<S: SP, E: EP> {
    let events: [E]
    let file: String
    let line: Int
    
    static func | (lhs: Self, rhs: S) -> WTARow<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, rhs: S) -> WTRow<S, E> {
        let wt = WhensThen(events: lhs.events,
                           state: rhs,
                           file: lhs.file,
                           line: lhs.line)
        
        return WTRow(wt: wt)
    }
    
    static func | (lhs: Self, rhs: S) -> WhensThen<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs,
                  file: lhs.file,
                  line: lhs.line)
    }
}

struct WhensThen<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WTARow<S, E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WTARow<S, E> {
        let wta = WhensThenActions(events: lhs.events,
                                   state: lhs.state,
                                   actions: rhs,
                                   file: lhs.file,
                                   line: lhs.line)
        return WTARow(wta: wta,
                      modifiers: .none)
    }
    
    let events: [E]
    let state: S
    let file: String
    let line: Int
}

struct WhensThenActions<S: SP, E: EP>: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.events == rhs.events &&
        lhs.state == rhs.state
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(events)
        hasher.combine(state)
    }
    
    let events: [E]
    let state: S
    let actions: [() -> ()]
    let file: String
    let line: Int
}
