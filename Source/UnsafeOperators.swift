//
//  ClassBasedOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import ReflectiveEquality

protocol StateProtocol {}
protocol EventProtocol {}

extension StateProtocol {
    var erased: Unsafe.AnyStateProtocol? {
        erase(self, to: Unsafe.AnyStateProtocol.init)
    }
}

extension EventProtocol {
    var erased: Unsafe.AnyEventProtocol? {
        erase(self, to: Unsafe.AnyEventProtocol.init)
    }
}

private func erase<ProtocolType, AnyProtocolType>(
    _ s: ProtocolType,
    to t: (ProtocolType) -> AnyProtocolType
) -> AnyProtocolType? {
    s is AnyProtocolType
    ? s as? AnyProtocolType
    : t(s)
}

enum Unsafe {
    private static func areEqual(lhs: Any, rhs: Any) -> Bool {
        if lhs is CustomStringConvertible || rhs is CustomStringConvertible {
            return String(describing: lhs) == String(describing: rhs)
        } else {
            return haveSameValue(lhs, rhs)
        }
    }
    
    private static func customHash(_ any: Any) -> String {
        if any is CustomStringConvertible {
            return String(describing: any)
        } else {
            return deepDescription(any)
        }
    }
    
    struct AnyEventProtocol: EventProtocol, Hashable {
        let base: any EventProtocol
        
        static func == (
            lhs: Unsafe.AnyEventProtocol,
            rhs: Unsafe.AnyEventProtocol
        ) -> Bool {
            areEqual(lhs: lhs, rhs: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(customHash(self))
        }
    }
    
    struct AnyStateProtocol: StateProtocol, Hashable {
        let base: any StateProtocol
        
        static func == (
            lhs: Unsafe.AnyStateProtocol,
            rhs: Unsafe.AnyStateProtocol
        ) -> Bool {
            areEqual(lhs: lhs, rhs: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(customHash(self))
        }
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
        
        init(_ event: any EventProtocol, _ state: any StateProtocol, _ action: @escaping () -> Void) {
            self.event = event
            self.state = state
            self.action = action
        }
    }
    
    struct StateEventState {
        let startState: any StateProtocol
        let event: any EventProtocol
        let endState: any StateProtocol
        
        init(_ startState: any StateProtocol, _ event: any EventProtocol, _ endState: any StateProtocol) {
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
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    states | esas.flatMap { $0 }
}

func | (
    states: [any StateProtocol],
    esas: [Unsafe.EventStateAction]
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    states.reduce(into: [Transition]()) {
        $0.append(contentsOf: $1 | esas)
    }
}

func | (
    state: any StateProtocol,
    esas: [[Unsafe.EventStateAction]]
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    state | esas.flatMap { $0 }
}

func | (
    state: any StateProtocol,
    esas: [Unsafe.EventStateAction]
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    esas.reduce(into: [Transition]()) {
        $0.append(Transition(givenState: state.erased!,
                             event: $1.event.erased!,
                             nextState: $1.state.erased!,
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
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    stateEventStates.reduce(into: [Transition]()) {
        $0.append(contentsOf: $1 | action)
    }
}

func | (
    stateEventState: Unsafe.StateEventState,
    action: @escaping () -> Void
) -> [Transition<Unsafe.AnyStateProtocol, Unsafe.AnyEventProtocol>] {
    [Transition(givenState: stateEventState.startState.erased!,
                event: stateEventState.event.erased!,
                nextState: stateEventState.endState.erased!,
                action: action)]
}
