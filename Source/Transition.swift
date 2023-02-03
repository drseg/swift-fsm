//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

class TransitionCollectionBase<S, E>: Equatable
where S: StateProtocol, E: EventProtocol {
    static func == (
        lhs: TransitionCollectionBase<S, E>,
        rhs: TransitionCollectionBase<S, E>
    ) -> Bool {
        lhs.transitions == rhs.transitions
    }
    
    let transitions: [Transition<S, E>]
    
    init(_ transitions: [Transition<S, E>]) {
        self.transitions = transitions
    }
}

struct Transition<S, E>: Hashable
where S: StateProtocol, E: EventProtocol {
    let givenState: S
    let event: E
    let nextState: S
    let actions: [() -> ()]
    
    let file: String
    let line: Int
    
    init(
        givenState: S,
        event: E,
        nextState: S,
        actions: [() -> Void],
        file: String = #file,
        line: Int = #line
    ) {
        self.givenState = givenState
        self.event = event
        self.nextState = nextState
        self.actions = actions
        self.file = file
        self.line = line
    }
    
    struct Key: Hashable {
        let state: S
        let event: E
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(givenState)
        hasher.combine(event)
        hasher.combine(nextState)
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock(
            _ ts: TransitionCollectionBase<S, E>...
        ) -> TransitionCollectionBase<S, E> {
            let transitions = ts.reduce(into: [Transition<S, E>]()) {
                $0.append(contentsOf: $1.transitions)
            }
            return TransitionCollectionBase<S, E>(transitions)
        }
        
        static func buildOptional(
            _ t: TransitionCollectionBase<S, E>?
        ) -> TransitionCollectionBase<S, E> {
            return t ?? TransitionCollectionBase([])
        }
        
        static func buildEither(
            first component: TransitionCollectionBase<S, E>
        ) -> TransitionCollectionBase<S, E> {
            component
        }
        
        static func buildEither(
            second component: TransitionCollectionBase<S, E>
        ) -> TransitionCollectionBase<S, E> {
            component
        }
    }
    
    static func build(
        @Transition.Builder _ content: () -> TransitionCollectionBase<S, E>
    ) -> [Transition]  {
        content().transitions
    }
    
    static func == (
        lhs: Transition<S,E>,
        rhs: Transition<S,E>
    ) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

