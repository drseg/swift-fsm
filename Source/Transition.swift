//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct FSMTableRowCollection<S: SP, E: EP> {
    let rows: [FSMTableRow<S, E>]
    
    var transitions: [Transition<S, E>] {
        rows.map(\.transitions).flatMap { $0 }
    }
}

struct FSMTableRow<S: SP, E: EP>: TransitionGroup {
    let transitions: [Transition<S, E>]
    let entryActions: [() -> ()]
    let exitActions: [() -> ()]
    
    var startStates: Set<S> {
        Set(transitions.map { $0.givenState })
    }
    
    init(
        _ transitions: [Transition<S, E>],
        entryActions: [() -> ()] = [],
        exitActions: [() -> ()] = []
    ) {
        self.transitions = transitions
        self.entryActions = entryActions
        self.exitActions = exitActions
    }
}

struct Transition<S: SP, E: EP>: Hashable {
    struct Key: Hashable {
        let state: S, event: E
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
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

