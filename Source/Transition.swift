//
//  SittingFSMInfix.swift
//  Sitting
//
//  Created by Daniel Segall on 28/01/2023.
//

import Foundation

struct Transition<S: SP, E: EP>: Equatable {
    struct Key: Hashable {
        let state: S, event: E, predicates: [AnyPredicate]
        
        init(state: S, event: E, predicates: [AnyPredicate] = []) {
            self.state = state
            self.event = event
            self.predicates = predicates
        }
    }
    
    let givenState: S
    let event: E
    let nextState: S
    let actions: [() -> ()]
    let predicates: [AnyPredicate]
    
    let file: String
    let line: Int
    
    init(g: S, w: E, t: S, a: [() -> ()], p: [AnyPredicate], f: String, l: Int) {
        givenState = g
        event = w
        nextState = t
        actions = a
        predicates = p
        file = f
        line = l
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.givenState == rhs.givenState &&
        lhs.event == rhs.event &&
        lhs.nextState == rhs.nextState
    }
}

