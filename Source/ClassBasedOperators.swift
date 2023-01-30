//
//  ClassBasedOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

extension StateProtocol {
    var erased: Unsafe.AnyStateProtocol? {
        Unsafe.AnyStateProtocol(base: self)
    }
}

extension EventProtocol {
    var erased: Unsafe.AnyEventProtocol? {
        Unsafe.AnyEventProtocol(base: self)
    }
}

enum Unsafe {
    struct AnyEventProtocol: EventProtocol {
        static func == (lhs: Unsafe.AnyEventProtocol, rhs: Unsafe.AnyEventProtocol) -> Bool {
            String(describing: lhs) == String(describing: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }
        
        let base: any EventProtocol
    }
    
    struct AnyStateProtocol: StateProtocol {
        let base: any StateProtocol
        
        static func == (lhs: Unsafe.AnyStateProtocol, rhs: Unsafe.AnyStateProtocol) -> Bool {
            String(describing: lhs) == String(describing: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }
    }
    
    class StateEvent {
        let state: any StateProtocol
        let event: any EventProtocol
        
        init(_ state: any StateProtocol, _ event: any EventProtocol) {
            self.state = state
            self.event = event
        }
    }
    
    class EventState {
        let event: any EventProtocol
        let state: any StateProtocol
        
        init(_ event: any EventProtocol, _ state: any StateProtocol) {
            self.event = event
            self.state = state
        }
    }
    
    class StateEventState {
        let startState: any StateProtocol
        let event: any EventProtocol
        let endState: any StateProtocol
        
        init(_ startState: any StateProtocol, _ event: any EventProtocol, _ endState: any StateProtocol) {
            self.startState = startState
            self.event = event
            self.endState = endState
        }
    }
    
    class StateAction {
        let state: any StateProtocol
        let action: () -> Void
        
        init(_ state: any StateProtocol, _ action: @escaping () -> Void) {
            self.state = state
            self.action = action
        }
    }
}

func | (state: any StateProtocol, event: any EventProtocol) -> Unsafe.StateEvent {
    Unsafe.StateEvent(state, event)
}

func | (states: [any StateProtocol], event: any EventProtocol) -> [Unsafe.StateEvent] {
    states.reduce(into: [Unsafe.StateEvent]()) {
        $0.append($1 | event)
    }
}

func | (states: [any StateProtocol], events: [any EventProtocol]) -> [Unsafe.StateEvent] {
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
    events: [any EventProtocol],
    state: any StateProtocol
) -> [Unsafe.EventState] {
    events.reduce(into: [Unsafe.EventState]()) {
        $0.append($1 | state)
    }
}

func | (
    state: any StateProtocol,
    action: @escaping () -> Void
) -> Unsafe.StateAction {
    Unsafe.StateAction(state, action)
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
    let start = Unsafe.AnyStateProtocol(base: stateEventState.startState)
    let event = Unsafe.AnyEventProtocol(base: stateEventState.event)
    let next = Unsafe.AnyStateProtocol(base: stateEventState.endState)
    
    return [Transition(givenState: start,
                       event: event,
                       nextState: next,
                       action: action)]
}
