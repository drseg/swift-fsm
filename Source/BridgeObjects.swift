//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct TableRow<S: SP, E: EP> {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    let givenStates: any Collection<S>
}

struct WTAPRow<S: SP, E: EP> {
    let wtap: WTAP<S, E>?
    let modifiers: RowModifiers<S, E>
    
    init(
        wtap: WTAP<S, E>? = nil,
        modifiers: RowModifiers<S, E> = .none
    ) {
        self.wtap = wtap
        self.modifiers = modifiers
    }
}

struct TAPRow<S: SP> {
    static var empty: Self {
        .init(tap: .init())
    }
    
    let tap: TAP<S>
}

struct RowModifiers<S: SP, E: EP> {
    static var none: Self {
        .init()
    }
    
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
}

struct SuperState<S: SP, E: EP>: Hashable {
    let wtas: [WTAP<S, E>]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wtas)
    }
    
    init(@WTAPBuilder<S, E> _ content: () -> [WTAPRow<S, E>]) {
        wtas = content().wtas()
    }
}

struct Whens<S: SP, E: EP> {
    static func | (lhs: Self, _: ()) -> WTAPRow<S, E> {
        WhensThen(events: lhs.events,
                  state: nil,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, rhs: S) -> WTAPRow<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, _: ()) -> WhensThen<S, E> {
        WhensThen(events: lhs.events,
                  state: nil,
                  file: lhs.file,
                  line: lhs.line)
    }
    
    static func | (lhs: Self, rhs: S) -> WhensThen<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs,
                  file: lhs.file,
                  line: lhs.line)
    }
    
    let events: [E]
    let file: String
    let line: Int
}

struct WhensThen<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WTAPRow<S, E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WTAPRow<S, E> {
        let wtap = WTAP(events: lhs.events,
                        state: lhs.state,
                        actions: rhs,
                        predicates: [],
                        file: lhs.file,
                        line: lhs.line)
        return WTAPRow(wtap: wtap, modifiers: .none)
    }
    
    let events: [E]
    let state: S?
    let file: String
    let line: Int
}

struct TAP<S: SP> {
    let state: S?
    let actions: [() -> ()]
    let predicates: [AnyPredicate]
    
    init(
        state: S? = nil,
        actions: [() -> ()] = [],
        predicates: [AnyPredicate] = []
    ) {
        self.state = state
        self.actions = actions
        self.predicates = predicates
    }
}

struct WTAP<S: SP, E: EP>: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.events == rhs.events &&
        lhs.state == rhs.state &&
        lhs.predicates == rhs.predicates
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(events)
        hasher.combine(state)
        hasher.combine(predicates)
    }
    
    let events: [E]
    let state: S?
    let actions: [() -> ()]
    let predicates: [AnyPredicate]
    let file: String
    let line: Int
}
