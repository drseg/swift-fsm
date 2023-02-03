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
    
    func buildTransitions(@T.Builder _ content: () -> TransitionCollectionBase<State, Event>) throws {
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
            .map { "\n\($0.givenState) | \($0.event) | *\($0.nextState)* (\($0.file.name): line \($0.line))" }
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
    let localizedDescription: String
    
    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
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
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erased)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        _handleEvent(event.erased)
    }
}
