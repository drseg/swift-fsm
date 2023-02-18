//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct TableRow<S: SP, E: EP> {
    let wtaps: [WTAP<S, E>]
    let modifiers: RowModifiers<S, E>
    let givenStates: [S]
    
#warning("temporary use only for refactoring, to be discarded")
    var transitions: [Transition<S, E>] {
        givenStates.reduce(into: [Transition]()) { ts, given in
            wtaps.forEach {
                ts.append(contentsOf: $0.makeTransitions(given: given))
            }
        }
    }
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

struct WAPRow<E: EP> {
    let wap: WAP<E>
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
        wtas = content().wtaps()
    }
}

struct Match: Hashable {
    let allOf: [AnyPredicate]
    let anyOf: [AnyPredicate]
    
    init(allOf: [AnyPredicate] = [], anyOf: [AnyPredicate] = []) {
        self.allOf = allOf
        self.anyOf = anyOf
    }
    
    init(
        allOf: [any PredicateProtocol] = [],
        anyOf: [any PredicateProtocol] = []
    ) {
        self.allOf = allOf.erased
        self.anyOf = anyOf.erased
    }
    
    init() {
        self.allOf = []
        self.anyOf = []
    }
    
    static var none: Match {
        .init()
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        Set(lhs.anyOf) == Set(rhs.anyOf) && Set(lhs.allOf) == Set(rhs.allOf)
    }
    
    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.add(all: rhs.allOf, any: rhs.anyOf)
    }
    
    func add(all: [AnyPredicate] = [], any: [AnyPredicate] = []) -> Self {
        .init(allOf: self.allOf + all, anyOf: self.anyOf + any)
    }
}

struct Whens<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WAPRow<E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WAPRow<E> {
        let wap = WAP(events: lhs.events,
                      actions: rhs,
                      match: .none,
                      file: lhs.file,
                      line: lhs.line)
        return WAPRow(wap: wap)
    }
    
    static func | (lhs: Self, rhs: Then<S>) -> WTAPRow<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs.state,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, rhs: Then<S>) -> WhensThen<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs.state,
                  file: lhs.file,
                  line: lhs.line)
    }
    
    let events: [E]
    let file: String
    let line: Int
}

struct Then<S: StateProtocol> {
    let state: S?
    
    static func | (lhs: Self, rhs: @escaping () -> ()) -> TAPRow<S> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> TAPRow<S> {
        TAPRow(tap: TAP(state: lhs.state, actions: rhs, match: .none))
    }
}

struct WhensThen<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WTAPRow<S, E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WTAPRow<S, E> {
        let wtap = WTAP(events: lhs.events,
                        state: lhs.state,
                        actions: rhs,
                        match: .none,
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
    let match: Match
    
    init(
        state: S? = nil,
        actions: [() -> ()] = [],
        match: Match = .none
    ) {
        self.state = state
        self.actions = actions
        self.match = match
    }
}

struct WAP<E: EP> {
    let events: [E]
    let actions: [() -> ()]
    let match: Match
    let file: String
    let line: Int
}

struct WTAP<S: SP, E: EP>: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.events == rhs.events &&
        lhs.state == rhs.state &&
        lhs.match == rhs.match
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(events)
        hasher.combine(state)
        hasher.combine(match)
    }
    
    let events: [E]
    let state: S?
    let actions: [() -> ()]
    let match: Match
    let file: String
    let line: Int
}
