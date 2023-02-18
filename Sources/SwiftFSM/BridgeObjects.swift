//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

struct TableRow<S: SP, E: EP> {
    let wtams: [WTAM<S, E>]
    let modifiers: RowModifiers<S, E>
    let givenStates: [S]
    
#warning("temporary use only for refactoring, to be discarded")
    var transitions: [Transition<S, E>] {
        givenStates.reduce(into: [Transition]()) { ts, given in
            wtams.forEach {
                ts.append(contentsOf: $0.makeTransitions(given: given))
            }
        }
    }
}

struct WTAMRow<S: SP, E: EP> {
    let wtam: WTAM<S, E>?
    let modifiers: RowModifiers<S, E>
    
    init(
        wtam: WTAM<S, E>? = nil,
        modifiers: RowModifiers<S, E> = .none
    ) {
        self.wtam = wtam
        self.modifiers = modifiers
    }
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
    let wtams: [WTAM<S, E>]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wtams)
    }
    
    init(@WTAMBuilder<S, E> _ content: () -> [WTAMRow<S, E>]) {
        wtams = content().wtams()
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
        self.allOf = allOf.erase()
        self.anyOf = anyOf.erase()
    }
    
    init() {
        allOf = []
        anyOf = []
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
        .init(allOf: allOf + all, anyOf: anyOf + any)
    }
}

struct Whens<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WAM<E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WAM<E> {
        WAM(events: lhs.events,
            actions: rhs,
            match: .none,
            file: lhs.file,
            line: lhs.line)
        
    }
    
    static func | (lhs: Self, rhs: Then<S>) -> WTAMRow<S, E> {
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
    
    static func | (lhs: Self, rhs: @escaping () -> ()) -> TAM<S> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> TAM<S> {
        TAM(state: lhs.state, actions: rhs, match: .none)
    }
}

struct WhensThen<S: SP, E: EP> {
    static func | (lhs: Self, rhs: @escaping () -> ()) -> WTAMRow<S, E> {
        lhs | [rhs]
    }
    
    static func | (lhs: Self, rhs: [() -> ()]) -> WTAMRow<S, E> {
        let wtam = WTAM(events: lhs.events,
                        state: lhs.state,
                        actions: rhs,
                        match: .none,
                        file: lhs.file,
                        line: lhs.line)
        return WTAMRow(wtam: wtam, modifiers: .none)
    }
    
    let events: [E]
    let state: S?
    let file: String
    let line: Int
}

struct TAM<S: SP> {
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

struct WAM<E: EP> {
    let events: [E]
    let actions: [() -> ()]
    let match: Match
    let file: String
    let line: Int
}

struct WTAM<S: SP, E: EP>: Hashable {
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
    
    func addActions(_ a: [() -> ()]) -> Self {
        WTAM(events: events,
             state: state,
             actions: actions + a,
             match: match,
             file: file,
             line: line)
    }
    
    func replaceDefaultState(with s: S) -> Self {
        WTAM(events: events,
             state: state ?? s,
             actions: actions,
             match: match,
             file: file,
             line: line)
    }
}
