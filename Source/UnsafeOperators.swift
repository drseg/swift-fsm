//
//  ClassBasedOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

protocol StateProtocol: Hashable {}
protocol EventProtocol: Hashable {}

private extension Hashable {
    func isEqual(to rhs: any Hashable) -> Bool {
        guard let rhs = rhs as? Self else { return false }
        return rhs == self
    }
}

extension StateProtocol {
    var erased: Unsafe.AnyState {
        erase(self, to: Unsafe.AnyState.init)
    }
}

extension EventProtocol {
    var erased: Unsafe.AnyEvent {
        erase(self, to: Unsafe.AnyEvent.init)
    }
}

private func erase<ProtocolType, AnyProtocolType>(
    _ s: ProtocolType,
    to t: (ProtocolType) -> AnyProtocolType
) -> AnyProtocolType {
    t(s)
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

enum Unsafe {
    struct AnyEvent: Eraser, EventProtocol, Hashable {
        let base: any Hashable
    }
    
    struct AnyState: Eraser, StateProtocol, Hashable {
        let base: any Hashable
    }
    
    struct StateEvent {
        let state: any StateProtocol
        let event: any EventProtocol
        
        init(_ state: any StateProtocol, _ event: any EventProtocol) {
            self.state = state
            self.event = event
        }
    }
    
    struct EventState {
        let event: any EventProtocol
        let state: any StateProtocol
        
        init(_ event: any EventProtocol, _ state: any StateProtocol) {
            self.event = event
            self.state = state
        }
    }
    
    struct EventStateAction {
        let event: any EventProtocol
        let state: any StateProtocol
        let action: () -> Void
        
        init(
            _ event: any EventProtocol,
            _ state: any StateProtocol,
            _ action: @escaping () -> Void
        ) {
            self.event = event
            self.state = state
            self.action = action
        }
    }
    
    struct StateEventState {
        let startState: any StateProtocol
        let event: any EventProtocol
        let endState: any StateProtocol
        
        init(
            _ startState: any StateProtocol,
            _ event: any EventProtocol,
            _ endState: any StateProtocol
        ) {
            self.startState = startState
            self.event = event
            self.endState = endState
        }
    }
}

func | (
    state: any StateProtocol,
    event: any EventProtocol) -> Unsafe.StateEvent {
    Unsafe.StateEvent(state, event)
}

func | (
    state: any StateProtocol,
    events: [any EventProtocol]
) -> [Unsafe.StateEvent] {
    events.reduce(into: [Unsafe.StateEvent]()) {
        $0.append(state | $1)
    }
}

func | (
    states: [any StateProtocol],
    event: any EventProtocol) -> [Unsafe.StateEvent] {
    states.reduce(into: [Unsafe.StateEvent]()) {
        $0.append($1 | event)
    }
}

func | (
    states: [any StateProtocol],
    events: [any EventProtocol]) -> [Unsafe.StateEvent] {
    states.reduce(into: [Unsafe.StateEvent]()) { output, s in
        events.forEach {
            output.append(s | $0)
        }
    }
}

func | (
    event: any EventProtocol,
    state: any StateProtocol
) -> Unsafe.EventState {
    Unsafe.EventState(event, state)
}

func | (
    state: [any StateProtocol],
    es: [Unsafe.EventState]
) -> [Unsafe.StateEventState] {
    state.reduce(into: [Unsafe.StateEventState]()) {
        $0.append(contentsOf: $1 | es)
    }
}

func | (
    state: any StateProtocol,
    es: [Unsafe.EventState]
) -> [Unsafe.StateEventState] {
    es.reduce(into: [Unsafe.StateEventState]()) {
        $0.append(Unsafe.StateEventState(state, $1.event, $1.state))
    }
}

func | (
    states: [any StateProtocol],
    esas: [[Unsafe.EventStateAction]]
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    states | esas.flatMap { $0 }
}

func | (
    states: [any StateProtocol],
    esas: [Unsafe.EventStateAction]
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    states.reduce(into: [Transition]()) {
        $0.append(contentsOf: $1 | esas)
    }
}

func | (
    state: any StateProtocol,
    esas: [[Unsafe.EventStateAction]]
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    state | esas.flatMap { $0 }
}

func | (
    state: any StateProtocol,
    esas: [Unsafe.EventStateAction]
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    esas.reduce(into: [Transition]()) {
        $0.append(Transition(givenState: state.erased,
                             event: $1.event.erased,
                             nextState: $1.state.erased,
                             action: $1.action))
    }
}

func | (
    events: [any EventProtocol],
    state: any StateProtocol
) -> [Unsafe.EventState] {
    events.reduce(into: [Unsafe.EventState]()) {
        $0.append($1 | state)
    }
}

func | (
    ess: [Unsafe.EventState],
    action: @escaping () -> Void
) -> [Unsafe.EventStateAction] {
    ess.reduce(into: [Unsafe.EventStateAction]()) {
        $0.append($1 | action)
    }
}

func | (
    es: Unsafe.EventState,
    action: @escaping () -> Void
) -> Unsafe.EventStateAction {
    Unsafe.EventStateAction(es.event, es.state, action)
}

func | (
    stateEvents: [Unsafe.StateEvent],
    state: any StateProtocol
) -> [Unsafe.StateEventState] {
    stateEvents.reduce(into: [Unsafe.StateEventState]()) {
        $0.append($1 | state)
    }
}

func | (
    stateEvent: Unsafe.StateEvent,
    state: any StateProtocol
) -> Unsafe.StateEventState {
    Unsafe.StateEventState(stateEvent.state, stateEvent.event, state)
}

func | (
    stateEventStates: [Unsafe.StateEventState],
    action: @escaping () -> Void
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    stateEventStates.reduce(into: [Transition]()) {
        $0.append(contentsOf: $1 | action)
    }
}

func | (
    stateEventState: Unsafe.StateEventState,
    action: @escaping () -> Void
) -> [Transition<Unsafe.AnyState, Unsafe.AnyEvent>] {
    [Transition(givenState: stateEventState.startState.erased,
                event: stateEventState.event.erased,
                nextState: stateEventState.endState.erased,
                action: action)]
}
