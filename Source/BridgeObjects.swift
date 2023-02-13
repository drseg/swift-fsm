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
        Self(superStates: [], entryActions: [], exitActions: [])
    }
}

struct SuperState<S: SP, E: EP>: Hashable {
    let wtas: [WhensThenActions<S, E>]
    let file: String
    let line: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wtas)
    }
    
    init(@WTABuilder<S, E> _ content: () -> [any WTARowProtocol<S, E>], file: String = #file,
         line: Int = #line) {
        wtas = content().wtas()
        self.file = file
        self.line = line
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
                                   actions: rhs)
        return WTARow(wta: wta,
                      modifiers: .none,
                      file: lhs.file,
                      line: lhs.line)
    }
    
    let events: [E]
    let state: S
    
    private let file: String
    private let line: Int
    
    init(events: [E], state: S, file: String = "", line: Int = 0) {
        self.events = events
        self.state = state
        self.file = file
        self.line = line
    }
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
}
