//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct Transition<State, Event>: Hashable
where State: StateProtocol, Event: EventProtocol {
    let givenState: State
    let event: Event
    let nextState: State
    let actions: [() -> ()]
    
    struct Key: Hashable {
        let state: State
        let event: Event
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(givenState)
        hasher.combine(event)
        hasher.combine(nextState)
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock(
            _ ts: [Transition]...
        ) -> [Transition] {
            ts.flatMap {$0}
        }
        
        static func buildIf(
            _ ts: [Transition]?
        ) -> [Transition] {
            if let ts {
                return ts
            }
            return [Transition]()
        }
        
        static func buildEither(
            first component: [Transition]
        ) -> [Transition] {
            component
        }
        
        static func buildEither(
            second component: [Transition]
        ) -> [Transition] {
            component
        }
    }
    
    static func build(
        @Transition.Builder _ content: () -> [Transition]
    ) -> [Transition] {
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

