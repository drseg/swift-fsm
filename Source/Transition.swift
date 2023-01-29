//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct Transition<State,Event>: Equatable
where State: Hashable, Event: Hashable {
    let givenState: State
    let event: Event
    let nextState: State
    let action: () -> Void
    
    struct Key<State,Event>: Hashable where State: Hashable, Event: Hashable {
        let state: State
        let event: Event
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock(
            _ ts: [Transition]...
        ) -> [Key<State,Event>: Transition] {
            ts.flatMap {$0}.reduce(into: [Key<State,Event>: Transition]()) {
                $0[Key(state: $1.givenState, event: $1.event)] = $1
            }
        }
        
        static func buildIf(
            _ values: [Key<State,Event>: Transition]?
        ) -> [Transition] {
            if let values {
                return Array(values.values)
            } else {
                return [Transition<State,Event>]()
            }
        }
        
        static func buildEither(
            first component: [Key<State,Event>: Transition]
        ) -> [Transition] {
            Array(component.values)
        }
        
        static func buildEither(
            second component: [Key<State,Event>: Transition]
        ) -> [Transition] {
            Array(component.values)
        }
    }
    
    static func build(
        @Transition.Builder _ content: () -> [Key<State,Event>: Transition]
    ) -> [Key<State,Event>: Transition] {
        content()
    }
    
    static func == (
        lhs: Transition<State,Event>,
        rhs: Transition<State,Event>
    ) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

