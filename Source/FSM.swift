//
//  FSM.swift
//  FiniteStateMachineTests
//
//  Created by Daniel Segall on 29/01/2023.
//

import Foundation
import ReflectiveEquality

class FSM<S: SP, E: EP> {
    typealias T = Transition<S, E>
    typealias K = T.Key
    typealias TRP = TableRowProtocol<S, E>
    
    var transitionTable = [K: T]()
    var entryActions = [S: [() -> ()]]()
    var exitActions = [S: [() -> ()]]()
    
    var state: S
    
    init(initialState state: S) {
        self.state = state
    }
    
    func buildTransitions(
        @TableBuilder<S, E> _ tableRows: () -> [any TRP]
    ) throws {
        let rows = tableRows()
        
        makeEntryActions(from: rows)
        makeExitActions(from: rows)
        
        try addToTable(transitions(from: rows))
    }
    
    func makeEntryActions(from rows: [any TRP]) {
        makeActions(from: rows) {
            entryActions[$0] = $1.entryActions
        }
    }
    
    func makeExitActions(from rows: [any TRP]) {
        makeActions(from: rows) {
            exitActions[$0] = $1.exitActions
        }
    }
    
    func makeActions(
        from rows: [any TRP],
        _ block: (S, RowModifiers<S, E>) -> ()
    ) {
        rows.forEach { row in
            row.givenStates.forEach {
                block($0, row.modifiers)
            }
        }
    }
    
    func transitions(from rows: [any TRP]) -> [T] {
        rows.reduce(into: [T]()) { ts, row in
            row.modifiers.superStates.forEach { ss in
                row.givenStates.forEach { given in
                    ss.wtas.forEach { wta in
                        wta.events.forEach {
                            ts.append(
                                Transition(g: given,
                                           w: $0,
                                           t: wta.state,
                                           a: wta.actions,
                                           f: wta.file,
                                           l: wta.line)
                            )
                        }
                    }
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
    
    func handleEvent(_ event: E) {
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
