//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import ReflectiveEquality

class FSMBase<S, E> where S: SP, E: EP {
    typealias T = Transition<S, E>
    typealias K = T.Key
    
    var state: S
    var transitions = [K: T]()
    
    init(initialState state: S) {
        self.state = state
    }
    
    func buildTransitions(
        @FSMTableBuilder<S, E> _ ts: () -> [T]
    ) throws {
        var keys = Set<K>()
        var duplicates = [T]()
        
        transitions = ts().reduce(into: [K: T]()) {
            let k = K(state: $1.givenState, event: $1.event)
            if keys.contains(k) {
                if !duplicates.contains($0[k]!) {
                    duplicates.append($0[k]!)
                }
                duplicates.append($1)
            }
            else {
                keys.insert(k)
                $0[k] = $1
            }
        }
        
        guard duplicates.isEmpty else {
            throw DuplicateTransitions(duplicates)
        }
    }
    
    fileprivate func _handleEvent(_ event: E) {
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

final class FSM<S, E>: FSMBase<S, E> where S: SP, E: EP {
    override init(initialState state: S) {
        super.init(initialState: state)
    }
    
    func handleEvent(_ event: E) {
        _handleEvent(event)
    }
}

final class UnsafeFSM: FSMBase<AnyState, AnyEvent> {
    typealias AS = AnyState
    typealias AE = AnyEvent
    typealias T = Transition<AS, AE>
    
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erase)
    }
    
    override func buildTransitions(
        @FSMTableBuilder<AS, AE> _ t: () -> [T]
    ) throws {
        try validate(t())
        try super.buildTransitions(t)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        _handleEvent(event.erase)
    }
    
    private func validate(_ ts: [T]) throws {
        func validateObject<E: Eraser>(_ e: E) throws {
            guard !isNSObject(e.base) else {
                throw NSObjectError()
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
            
            guard areSameType(lhs: $0.givenState, rhs: $0.nextState) else {
                throw MismatchedType()
            }
        }
    }
}

struct DuplicateTransitions<S: SP, E: EP>: Error {
    private let message =
    "The same 'given-when' was found in multiple transitions:"
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

