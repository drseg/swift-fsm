//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct Transition<S, E>: Hashable
where S: StateProtocol, E: EventProtocol {
    class Group: Equatable {
        static func == (
            lhs: Group,
            rhs: Group
        ) -> Bool {
            lhs.transitions == rhs.transitions
        }
        
        let transitions: [Transition<S, E>]
        
        init(_ transitions: [Transition<S, E>]) {
            self.transitions = transitions
        }
    }
    
    struct Key: Hashable {
        let state: S
        let event: E
    }
    
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(givenState)
        hasher.combine(event)
        hasher.combine(nextState)
    }
    
    @resultBuilder
    struct Builder {
        static func buildBlock(
            _ ts: Group...
        ) -> Group {
            let transitions = ts.reduce(into: [Transition<S, E>]()) {
                $0.append(contentsOf: $1.transitions)
            }
            return Group(transitions)
        }
        
        static func buildOptional(
            _ t: Group?
        ) -> Group {
            return t ?? Group([])
        }
        
        static func buildEither(
            first component: Group
        ) -> Group {
            component
        }
        
        static func buildEither(
            second component: Group
        ) -> Group {
            component
        }
    }
    
    static func build(
        @Transition.Builder _ content: () -> Group
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

