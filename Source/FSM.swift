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
    
    var transitionTable = [K: T]()
    var entryActions = [S: [() -> ()]]()
    var exitActions = [S: [() -> ()]]()
    
    var state: S
    
    init(initialState state: S) {
        self.state = state
    }
    
    func buildTransitions(
        @TableBuilder<S, E> _ tableRows: () -> [any TableRowProtocol<S, E>]
    ) throws {
        let rows = tableRows()
        
        makeEntryActions(from: rows)
        makeExitActions(from: rows)
        
        try addToTable(transitions(from: rows))
    }
    
    func makeEntryActions(from rows: [any TableRowProtocol<S, E>]) {
        makeActions(from: rows) {
            entryActions[$0] = $1.entryActions
        }
    }
    
    func makeExitActions(from rows: [any TableRowProtocol<S, E>]) {
        makeActions(from: rows) {
            exitActions[$0] = $1.exitActions
        }
    }
    
    func makeActions(
        from rows: [any TableRowProtocol<S, E>],
        _ block: (S, RowModifiers<S, E>) -> ()
    ) {
        rows.forEach { row in
            row.givenStates.forEach {
                block($0, row.modifiers)
            }
        }
    }
    
    func transitions(from rows: [any TableRowProtocol<S, E>]) -> [T] {
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
    
    func addToTable(_ ts: [T]) throws {
        var keys = Set<K>()
        var duplicates = [T]()
        
        ts.forEach {
            let k = K(state: $0.givenState, event: $0.event)
            
            if keys.contains(k) {
                let existing = transitionTable[k]!
                if !duplicates.contains(existing) {
                    duplicates.append(existing)
                }
                duplicates.append($0)
            }
            
            keys.insert(k)
            transitionTable[k] = $0
        }
        
        if !duplicates.isEmpty {
            try throwError(DuplicateTransitions(duplicates))
        }
    }
    
    func throwError(_ e: Error) throws {
        throw e
    }
    
    func _handleEvent(_ event: E) {
        let key = K(state: state, event: event)
        
        if let t = transitionTable[key] {
            let previousState = state
            
            t.actions.executeAll()
            state = t.nextState
            
            executeExitActions(previousState: previousState)
            executeEntryActions(previousState: previousState)
        }
    }
    
    func executeEntryActions(previousState: S) {
        if let entries = entryActions[state], state != previousState  {
            entries.executeAll()
        }
    }
    
    func executeExitActions(previousState: S) {
        if let exits = exitActions[previousState], state != previousState {
            exits.executeAll()
        }
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
