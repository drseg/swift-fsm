//
//  ClassBasedOperators.swift
//  FiniteStateMachine
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

enum Class {
    class HashableBase: Hashable {
        static func == (lhs: HashableBase, rhs: HashableBase) -> Bool {
            type(of: lhs) == type(of: rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }
    }
    
    class State: HashableBase { }
    class Event: HashableBase { }
    
    class StateEvent {
        let state: State
        let event: Event
        
        init(_ state: State, _ event: Event) {
            self.state = state
            self.event = event
        }
    }
    
    class EventState {
        let event: Event
        let state: State
        
        init(_ event: Event, _ state: State) {
            self.event = event
            self.state = state
        }
    }
    
    class StateEventState {
        let startState: State
        let event: Event
        let endState: State
        
        init(_ startState: State, _ event: Event, _ endState: State) {
            self.startState = startState
            self.event = event
            self.endState = endState
        }
    }
    
    class StateAction {
        let state: State
        let action: () -> Void
        
        init(_ state: State, _ action: @escaping () -> Void) {
            self.state = state
            self.action = action
        }
    }
}

func | (state: Class.State, event: Class.Event) -> Class.StateEvent {
    Class.StateEvent(state, event)
}

func | (states: [Class.State], event: Class.Event) -> [Class.StateEvent] {
    states.reduce(into: [Class.StateEvent]()) {
        $0.append($1 | event)
    }
}

func | (states: [Class.State], events: [Class.Event]) -> [Class.StateEvent] {
    states.reduce(into: [Class.StateEvent]()) { output, s in
        events.forEach {
            output.append(s | $0)
        }
    }
}

func | (event: Class.Event, state: Class.State) -> Class.EventState {
    Class.EventState(event, state)
}

func | (events: [Class.Event], state: Class.State) -> [Class.EventState] {
    events.reduce(into: [Class.EventState]()) {
        $0.append($1 | state)
    }
}

func | (
    state: Class.State,
    action: @escaping () -> Void
) -> Class.StateAction {
    Class.StateAction(state, action)
}

func | (
    stateEvent: Class.StateEvent,
    state: Class.State
) -> Class.StateEventState {
    Class.StateEventState(stateEvent.state, stateEvent.event, state)
}

func | (
    stateEvents: [Class.StateEvent],
    state: Class.State
) -> [Class.StateEventState] {
    stateEvents.reduce(into: [Class.StateEventState]()) {
        $0.append(Class.StateEventState($1.state, $1.event, state))
    }
}

func | (
    stateEventState: Class.StateEventState,
    action: @escaping () -> Void
) -> [Transition<Class.State, Class.Event>] {
    [Transition(givenState: stateEventState.startState,
                event: stateEventState.event,
                nextState: stateEventState.endState,
                action: action)]
}

func | (
    stateEventStates: [Class.StateEventState],
    action: @escaping () -> Void
) -> [Transition<Class.State, Class.Event>] {
    stateEventStates.reduce(into: [Transition]()) {
        $0.append(
            Transition(givenState: $1.startState,
                       event: $1.event,
                       nextState: $1.endState,
                       action: action)
        )
    }
}
