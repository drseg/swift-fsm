//
//  ClassBasedTransition.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

protocol TransitionConvertible {
    func asArray() -> [Base.Transition]
}

extension Base.Transition: TransitionConvertible {
    func asArray() -> [Base.Transition] {
        [self]
    }
}

extension Array: TransitionConvertible where Element == Base.Transition {
    func asArray() -> [Base.Transition] {
        self
    }
}

enum Base {
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
    
    struct Transition: Equatable {
        let givenState: State
        let event: Event
        let nextState: State
        let action: () -> Void
        
        struct Key: Hashable {
            let given: State
            let event: Event
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(given)
                hasher.combine(event)
            }
        }
        
        @resultBuilder
        struct Builder {
            static func buildBlock(
                _ transitions: TransitionConvertible...
            ) -> [Key: Transition] {
                transitions.map { $0.asArray() }.flatMap { $0 }.reduce(into: [Key: Transition]()) {
                    $0[Key(given: $1.givenState, event: $1.event)] = $1
                }
            }
            
            static func buildIf(
                _ values: [Key: Transition]?
            ) -> [Transition] {
                if let values {
                    return Array(values.values)
                } else {
                    return [Transition]()
                }
            }
            
            static func buildEither(
                first component: [Key: Transition]
            ) -> [Transition] {
                Array(component.values)
            }
            
            static func buildEither(
                second component: [Key: Transition]
            ) -> [Transition] {
                Array(component.values)
            }
        }
        
        static func build(
            @Transition.Builder _ content: () -> [Key: Transition]
        ) -> [Key: Transition] {
            content()
        }
        
        static func == (
            lhs: Transition,
            rhs: Transition
        ) -> Bool {
            lhs.givenState == rhs.givenState &&
            lhs.event == rhs.event &&
            lhs.nextState == rhs.nextState
        }
    }
}

func | (state: Base.State, event: Base.Event) -> Base.StateEvent {
    Base.StateEvent(state, event)
}

func | (states: [Base.State], event: Base.Event) -> [Base.StateEvent] {
    states.reduce(into: [Base.StateEvent]()) {
        $0.append($1 | event)
    }
}

func | (states: [Base.State], events: [Base.Event]) -> [Base.StateEvent] {
    states.reduce(into: [Base.StateEvent]()) { output, s in
        events.forEach {
            output.append(s | $0)
        }
    }
}

func | (event: Base.Event, state: Base.State) -> Base.EventState {
    Base.EventState(event, state)
}

func | (events: [Base.Event], state: Base.State) -> [Base.EventState] {
    events.reduce(into: [Base.EventState]()) {
        $0.append($1 | state)
    }
}

func | (state: Base.State, action: @escaping () -> Void) -> Base.StateAction {
    Base.StateAction(state, action)
}

func | (stateEvent: Base.StateEvent, state: Base.State) -> Base.StateEventState {
    Base.StateEventState(stateEvent.state, stateEvent.event, state)
}

func | (stateEvents: [Base.StateEvent], state: Base.State) -> [Base.StateEventState] {
    stateEvents.reduce(into: [Base.StateEventState]()) {
        $0.append(Base.StateEventState($1.state, $1.event, state))
    }
}

func | (stateEventState: Base.StateEventState, action: @escaping () -> Void) -> Base.Transition {
    Base.Transition(givenState: stateEventState.startState, event: stateEventState.event, nextState: stateEventState.endState, action: action)
}

func | (stateEventStates: [Base.StateEventState], action: @escaping () -> Void) -> [Base.Transition] {
    stateEventStates.reduce(into: [Base.Transition]()) {
        $0.append(
        Base.Transition(givenState: $1.startState, event: $1.event, nextState: $1.endState, action: action)
        )
    }
}
