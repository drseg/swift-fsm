//
//  ClassBasedOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}

extension StateProtocol {
    var erase: AnyState { AnyState(base: self) }
}

extension EventProtocol {
    var erase: AnyEvent { AnyEvent(base: self) }
}

protocol Eraser {
    var base: any Hashable { get }
}

extension Eraser {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.base.isEqual(to: rhs.base)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

private extension Hashable {
    func isEqual(to rhs: any Hashable) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return rhs == self
    }
}

struct AnyEvent: Eraser, EventProtocol {
    let base: any Hashable
}

struct AnyState: Eraser, StateProtocol {
    let base: any Hashable
}

typealias SP = StateProtocol
typealias EP = EventProtocol
typealias AS = AnyState
typealias AE = AnyEvent
typealias AnyTransition = Transition<AS, AE>

struct StateEvent {
    let state: any SP
    let event: any EP
    
    init(_ state: any SP, _ event: any EP) {
        self.state = state
        self.event = event
    }
}

struct EventState {
    let event: any EP
    let state: any SP
    
    init(_ event: any EP, _ state: any SP) {
        self.event = event
        self.state = state
    }
}

struct EventStateAction {
    let event: any EP
    let state: any SP
    let actions: [() -> ()]
    
    init(
        _ event: any EP,
        _ state: any SP,
        _ actions: [() -> ()]
    ) {
        self.event = event
        self.state = state
        self.actions = actions
    }
}

struct StateEventState {
    let startState: any SP
    let event: any EP
    let endState: any SP
    
    init(
        _ startState: any SP,
        _ event: any EP,
        _ endState: any SP
    ) {
        self.startState = startState
        self.event = event
        self.endState = endState
    }
}

func | (state: any SP, event: any EP) -> StateEvent {
    StateEvent(state, event)
}

func | (state: any SP, events: [any EP]) -> [StateEvent] {
    events.reduce(into: [StateEvent]()) {
        $0.append(state | $1)
    }
}

func | (states: [any SP], event: any EP) -> [StateEvent] {
    states.reduce(into: [StateEvent]()) {
        $0.append($1 | event)
    }
}

func | (states: [any SP], events: [any EP]) -> [StateEvent] {
    states.reduce(into: [StateEvent]()) { output, s in
        events.forEach {
            output.append(s | $0)
        }
    }
}

func | (event: any EP, state: any SP) -> EventState {
    EventState(event, state)
}

func | (state: [any SP], es: [EventState]) -> [StateEventState] {
    state.reduce(into: [StateEventState]()) {
        $0.append(contentsOf: $1 | es)
    }
}

func | (state: any SP, es: [EventState]) -> [StateEventState] {
    es.reduce(into: [StateEventState]()) {
        $0.append(StateEventState(state, $1.event, $1.state))
    }
}

func | (events: [any EP], state: any SP) -> [EventState] {
    events.reduce(into: [EventState]()) {
        $0.append($1 | state)
    }
}

func | (ess: [EventState], action: @escaping () -> ()) -> [EventStateAction] {
    ess | [action]
}

func | (ess: [EventState], actions: [() -> ()]) -> [EventStateAction] {
    ess.reduce(into: [EventStateAction]()) {
        $0.append($1 | actions)
    }
}

func | (es: EventState, action: @escaping () -> ()) -> EventStateAction {
    es | [action]
}

func | (es: EventState, actions: [() -> ()]) -> EventStateAction {
    EventStateAction(es.event, es.state, actions)
}

func | (stateEvents: [StateEvent], state: any SP) -> [StateEventState] {
    stateEvents.reduce(into: [StateEventState]()) {
        $0.append($1 | state)
    }
}

func | (stateEvent: StateEvent, state: any SP) -> StateEventState {
    StateEventState(stateEvent.state, stateEvent.event, state)
}


func | (states: [any SP], esas: [[EventStateAction]]) -> TableRow<AS, AE> {
    states | esas.flatten
}

func | (states: [any SP], esas: [EventStateAction]) -> TableRow<AS, AE> {
    TableRow(
        transitions: states.reduce(into: [Transition]()) {
            $0.append(contentsOf: ($1 | esas).transitions)
        },
        modifiers: .none)
}

func | (state: any SP, esas: [[EventStateAction]]) -> TableRow<AS, AE> {
    state | esas.flatten
}

func | (state: any SP, esas: [EventStateAction]) -> TableRow<AS, AE> {
    TableRow(
        transitions: esas.reduce(into: [Transition]()) {
            $0.append(Transition(givenState: state.erase,
                                 event: $1.event.erase,
                                 nextState: $1.state.erase,
                                 actions: $1.actions))
        },
        modifiers: .none)
}

func | (sess: [StateEventState], action: @escaping () -> ()) -> TableRow<AS, AE> {
    sess | [action]
}

func | (sess: [StateEventState], actions: [() -> ()]) -> TableRow<AS, AE> {
    TableRow (
        transitions: sess.reduce(into: [Transition]()) {
            $0.append(contentsOf: ($1 | actions).transitions)
        },
        modifiers: .none)
}

func | (ses: StateEventState, action: @escaping () -> ()) -> TableRow<AS, AE> {
    ses | [action]
}

func | (ses: StateEventState, actions: [() -> ()]) -> TableRow<AS, AE> {
    TableRow(
        transitions: [Transition(givenState: ses.startState.erase,
                    event: ses.event.erase,
                    nextState: ses.endState.erase,
                    actions: actions)],
        modifiers: .none)
}
