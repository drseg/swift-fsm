//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

protocol TransitionGroup {
    associatedtype State: StateProtocol
    associatedtype Event: EventProtocol
        
    var transitions: [Transition<State, Event>] { get }
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
        @TransitionBuilder<S, E> _ content: () -> ([Transition<S, E>])
    ) -> [Transition<S, E>] {
        content()
    }
    
    static func == (lhs: Transition<S, E>, rhs: Transition<S, E>) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

