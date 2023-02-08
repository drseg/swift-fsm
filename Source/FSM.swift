//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import ReflectiveEquality

class FSMBase<S: SP, E: EP> {
    typealias T = Transition<S, E>
    typealias K = T.Key
    
    var state: S
    var transitions = [K: T]()
    
    init(initialState state: S) {
        self.state = state
    }
    
    func buildTransitions(
        @TableBuilder<S, E> _ ts: () -> [any TableRowProtocol<S, E>]
    ) throws {
        var keys = Set<K>()
        var duplicates = [T]()
        
        transitions = makeTransitions(from: ts()).reduce(into: [K: T]()) {
            let k = K(state: $1.givenState, event: $1.event)
            
            if keys.contains(k) {
                let existing = $0[k]!
                if !duplicates.contains(existing) {
                    duplicates.append(existing)
                }
                duplicates.append($1)
            }
            
            keys.insert(k)
            $0[k] = $1
        }
        
        if !duplicates.isEmpty {
            try throwError(DuplicateTransitions(duplicates))
        }
    }
    
    func _handleEvent(_ event: E) {
        let key = K(state: state, event: event)
        if let t = transitions[key] {
            t.actions.forEach { $0() }
            state = t.nextState
        }
    }
    
    func makeTransitions(from rows: [any TableRowProtocol<S, E>]) -> [T] {
        rows.reduce(into: [T]()) { ts, row in
            row.modifiers.superStates.map(\.wtas).flatten.forEach { wta in
                row.givenStates.forEach { given in
                    ts.append(
                        Transition(givenState: given,
                                   event: wta.when,
                                   nextState: wta.then,
                                   actions: wta.actions)
                    )
                }
            }
        } + rows.transitions()
    }
    
    func throwError(_ e: Error) throws {
        throw e
    }
}

class FSM<S: SP, E: EP>: FSMBase<S, E> {
    override init(initialState state: S) {
        super.init(initialState: state)
    }
    
    func handleEvent(_ event: E) {
        _handleEvent(event)
    }
}

class AnyFSM: FSMBase<AnyState, AnyEvent> {
    typealias AS = AnyState
    typealias AE = AnyEvent
    
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erase)
    }
    
    override func buildTransitions(
        @TableBuilder<AS, AE> _ t: () -> [any TableRowProtocol<AS, AE>]
    ) throws {
        try validate(t().transitions())
        try super.buildTransitions(t)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        _handleEvent(event.erase)
    }
    
    func validate(_ ts: [T]) throws {
        func validateObject<E: Eraser>(_ e: E) throws {
            if isNSObject(e.base) {
                try throwError(NSObjectError())
            }
        }
        
        func isNSObject(_ a: Any) -> Bool {
            deepDescription(a).contains("NSObject")
        }
        
        func areSameType<E: Eraser>(lhs: E, rhs: E) -> Bool {
            type(of: lhs.base) == type(of: rhs.base)
        }
        
        try ts.forEach {
            try validateObject($0.givenState)
            try validateObject($0.event)
            try validateObject($0.nextState)
            
            if !areSameType(lhs: $0.givenState, rhs: $0.nextState) {
                try throwError(MismatchedType())
            }
        }
    }
}

struct DuplicateTransitions<S: SP, E: EP>: Error {
    let message = "The same 'given-when' was found in multiple transitions:"
    let description: String
    
    init<C: Collection>(_ ts: C) where C.Element == Transition<S, E> {
        self.description =  message + ts.map {
            "\n\($0.givenState) | \($0.event) | *\($0.nextState)* (\($0.file.name): \($0.line))"
        }
        .sorted()
        .joined()
    }
}

struct NSObjectError: Error {
    var description: String {
        "States and Events must not inherit from, or include NSObject"
    }
}

struct MismatchedType: Error {
    var description: String {
        "Given and Then states must be of the same type"
    }
}

private extension String {
    var name: String {
        URL(string: self)?.lastPathComponent ?? self
    }
}
