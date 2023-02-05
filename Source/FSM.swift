//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation

class FSMBase<State, Event>
where State: StateProtocol, Event: EventProtocol {
    typealias T = Transition<State, Event>
    typealias K = T.Key
    typealias S = State
    typealias E = Event
    
    var state: State
    var transitions = [K: T]()
    
    init(initialState state: State) {
        self.state = state
    }
    
    func buildTransitions(@TransitionBuilder<S, E> _ c: () -> TGroup<S, E>) throws {
        var keys = Set<K>()
        var invalidTransitions = Set<T>()
        
        transitions = c().transitions.reduce(into: [K: T]()) {
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
            throw ConflictingTransitionError(invalidTransitions)
        }
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
#warning("Should this also throw for duplicate valid transitions?")

final class FSM<State, Event>: FSMBase<State, Event>
where State: SP, Event: EP {
    override init(initialState state: State) {
        super.init(initialState: state)
    }
    
    func handleEvent(_ event: Event) {
        _handleEvent(event)
    }
}

final class UnsafeFSM: FSMBase<AnyState, AnyEvent> {
    typealias US = AnyState
    typealias UE = AnyEvent
    typealias T = Transition<US, UE>
    
    init(initialState state: any StateProtocol) {
        super.init(initialState: state.erased)
    }
    
    override func buildTransitions(
        @TransitionBuilder<US, UE> _ content: () -> TGroup<US, UE>
    ) throws {
        try validate(content().transitions)
        try super.buildTransitions(content)
    }
    
    func handleEvent(_ event: any EventProtocol) {
        _handleEvent(event.erased)
    }
    
    private func validate(_ ts: [T]) throws {
        func validateObject<E: Eraser>(_ e: E) throws {
            guard !isNSObject(e.base) else {
                throw NSObjectError()
            }
        }
        
        func isNSObject(_ a: Any) -> Bool {
            let mirror = Mirror(reflecting: a)
            return a is NSObject
            && (mirror.superclassMirror != nil ||
                String(describing: a).contains("NSObject"))
        }
#warning("This is not a complete check")
        
        func areSameType<E: Eraser>(lhs: E, rhs: E) -> Bool {
            type(of: lhs.base) == type(of: rhs.base)
        }
        
        try ts.forEach {
            try validateObject($0.givenState)
            try validateObject($0.event)
            try validateObject($0.nextState)
            
            guard areSameType(lhs: $0.givenState, rhs: $0.nextState) else {
                throw MismatchedTypeError()
            }
        }
    }
}

struct ConflictingTransitionError<S: SP, E: EP>: Error {
    let message =
    """
    The same 'given-when' combination cannot lead to more than one 'then' state.

    The following conflicts were found:
    """
    
    let description: String
    
    init(_ ts: Set<Transition<S, E>>) {
        self.description =  message + ts.map {
            "\n\($0.givenState) | \($0.event) | *\($0.nextState)* (\($0.file.name): line \($0.line))"
        }.sorted().joined()
    }
}

struct NSObjectError: Error {
    var description: String {
        "States and Events must not inherit from NSObject"
    }
}

struct MismatchedTypeError: Error {
    var description: String {
        "Given and Then states must be of the same type"
    }
}

