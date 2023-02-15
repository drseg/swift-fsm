//
//  SafeObjects.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 01/02/2023.
//

import Foundation

protocol TableRowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var transitions: [Transition<State, Event>] { get }
    var modifiers: RowModifiers<State, Event> { get }
    var givenStates: any Collection<State> { get }
}

struct TableRow<S: SP, E: EP>: TableRowProtocol {
    let transitions: [Transition<S, E>]
    let modifiers: RowModifiers<S, E>
    let givenStates: any Collection<S>
}

protocol WTARowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var wta: WhensThenActions<State, Event>? { get }
    var modifiers: RowModifiers<State, Event> { get }
}

struct WTARow<S: SP, E: EP>: WTARowProtocol {
    let wta: WhensThenActions<S, E>?
    let modifiers: RowModifiers<S, E>
    
    init(
        wta: WhensThenActions<S, E>? = nil,
        modifiers: RowModifiers<S, E> = .none
    ) {
        self.wta = wta
        self.modifiers = modifiers
    }
}

protocol WTRowProtocol<State, Event> {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
    
    var wt: WhensThen<State, Event> { get }
}

struct WTRow<S: SP, E: EP>: WTRowProtocol {
    let wt: WhensThen<S, E>
}

struct RowModifiers<S: SP, E: EP> {
    static var none: Self {
        Self()
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
    let wtas: [WhensThenActions<S, E>]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wtas)
    }
    
    init(@WTABuilder<S, E> _ content: () -> [any WTARowProtocol<S, E>]) {
        wtas = content().wtas()
    }
}

struct Whens<S: SP, E: EP> {
    static func | (lhs: Self, _: ()) -> WTARow<S, E> {
        WhensThen(events: lhs.events,
                  state: nil,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, rhs: S) -> WTARow<S, E> {
        WhensThen(events: lhs.events,
                  state: rhs,
                  file: lhs.file,
                  line: lhs.line) | []
    }
    
    static func | (lhs: Self, rhs: ()) -> WTRow<S, E> {
        let wt = WhensThen<S, E>(events: lhs.events,
                                 state: nil,
                                 file: lhs.file,
                                 line: lhs.line)
        
        return WTRow(wt: wt)
    }
    
    static func | (lhs: Self, rhs: S) -> WTRow<S, E> {
        let wt = WhensThen(events: lhs.events,
                           state: rhs,
                           file: lhs.file,
                           line: lhs.line)
        
        return WTRow(wt: wt)
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
    let state: S?
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
    let state: S?
    let actions: [() -> ()]
    let file: String
    let line: Int
}
