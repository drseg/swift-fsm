//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

class FSMBase<State, Event> where State: StateProtocol, Event: EventProtocol {
    typealias T = Transition<State, Event>
    typealias K = T.Key
    
    var state: State
    var transitions = [K: T]()
    
    init(initialState state: State) {
        self.state = state
    }
    
    func buildTransitions(@T.Builder _ content: () -> Transition<State, Event>.Group) throws {
        var keys = Set<K>()
        var invalidTransitions = Set<T>()
        
        transitions = content().transitions.reduce(into: [K: T]()) {
            let k = K(state: $1.givenState, event: $1.event)
            if keys.contains(k) {
                invalidTransitions.insert($0[k]!)
                invalidTransitions.insert($1)
            }
            else {
                keys.insert(k)
                $0[k] = $1
            }
        }
        
        guard invalidTransitions.isEmpty else {
            try throwError(invalidTransitions)
        }
    }
    
    private func throwError(_ ts: Set<T>) throws -> Never {
        let message =
"""
The same 'given-when' combination cannot lead to more than one 'then' state.

The following conflicts were found:
"""
        let conflicts = ts
            .map {
                "\n\($0.givenState) | \($0.event) | *\($0.nextState)* (\($0.file.name): line \($0.line))"
            }
            .sorted()
            .joined()
        throw ConflictingTransitionError(message + conflicts)
    }
    
    fileprivate func _handleEvent(_ event: Event) {
        let key = K(state: state, event: event)
        if let t = transitions[key] {
            t.actions.forEach { $0() }
            state = t.nextState
        }
    }
}

private extension String {
    var name: String {
        URL(string: self)?.lastPathComponent ?? self
    }
}

struct ConflictingTransitionError: Error {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
}
#warning("Should this also throw for duplicate valid transitions?")

final class FSM<State, Event>: FSMBase<State, Event> where State: StateProtocol, Event: EventProtocol {
    override init(initialState state: State) {
        super.init(initialState: state)
    }
    
    func handleEvent(_ event: Event) {
        _handleEvent(event)
    }
}

final class UnsafeFSM: FSMBase<Unsafe.AnyState, Unsafe.AnyEvent> {
    typealias T = Transition<Unsafe.AnyState, Unsafe.AnyEvent>
    
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erased)
    }
    
    override func buildTransitions(
        @T.Builder _ content: () -> T.Group
    ) throws {
        try validate(content().transitions)
        try super.buildTransitions(content)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        _handleEvent(event.erased)
    }
    
    private func validate(
        _ ts: [T]
    ) throws {
        func validateObject(_ a: Any) throws {
            let mirror = Mirror(reflecting: a)
            if a is NSObject
                && (mirror.superclassMirror != nil ||
                    String(describing: a).contains("NSObject")) {
                throw NSObjectError(
                    "States and Events must not inherit from NSObject"
                )
            }
        }
        
        func areSameType(lhs: Any, rhs: Any) -> Bool {
            type(of: lhs) == type(of: rhs)
        }
        
        try ts.forEach {
            try validateObject($0.givenState.base)
            try validateObject($0.event.base)
            try validateObject($0.nextState.base)
            
            guard areSameType(lhs: $0.givenState.base,
                              rhs: $0.nextState.base) else {
                throw MismatchedTypeError(
                    "Given and Then states must be of the same type"
                )
            }
        }
    }
    
    struct NSObjectError: Error {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
    
    struct MismatchedTypeError: Error {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
    }
}
