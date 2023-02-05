//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

class TGroup<S: SP, E: EP>: Equatable {
    static func == (lhs: TGroup, rhs: TGroup) -> Bool {
        lhs.transitions == rhs.transitions
    }
    
    var transitions: [Transition<S, E>] = []
    
    convenience init(_ transitions: [Transition<S, E>]) {
        self.init()
        self.transitions = transitions
    }
}

struct Transition<S: SP, E: EP>: Hashable {
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
    
    static func build(
        @TransitionBuilder<S, E> _ content: () -> TGroup<S, E>
    ) -> [Transition]  {
        content().transitions
    }
    
    static func == (lhs: Transition<S, E>, rhs: Transition<S, E>) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

