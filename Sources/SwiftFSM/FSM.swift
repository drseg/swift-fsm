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
    typealias TRP = TableRow<S, E>
    
    var transitionTable = [K: T]()
    var entryActions = [S: [() -> ()]]()
    var exitActions = [S: [() -> ()]]()
    
    var state: S
    
    init(initialState state: S) {
        self.state = state
    }
    
    func buildTransitions(
        @TableBuilder<S, E> _ tableRows: () -> [TRP]
    ) throws {
        let rows = tableRows()
        
        makeEntryActions(from: rows)
        makeExitActions(from: rows)
        
        try addToTable(transitions(from: rows))
        
        if includeNSObject {
            try throwError(NSObjectError())
        }
    }
    
    var includeNSObject: Bool {
        deepDescription([transitionTable.keys.first?.state as Any,
                         transitionTable.keys.first?.event as Any])
        .contains("NSObject")
    }
    
    func makeEntryActions(from rows: [TRP]) {
        makeActions(from: rows) {
            entryActions[$0] = $1.entryActions
        }
    }
    
    func makeExitActions(from rows: [TRP]) {
        makeActions(from: rows) {
            exitActions[$0] = $1.exitActions
        }
    }
    
    func makeActions(
        from rows: [TRP],
        _ block: (S, RowModifiers<S, E>) -> ()
    ) {
        rows.forEach { row in
            row.givenStates.forEach {
                block($0, row.modifiers)
            }
        }
    }
    
    func transitions(from rows: [TRP]) -> [T] {
        rows.reduce(into: [T]()) { ts, row in
            row.modifiers.superStates.forEach {
                ts.append(
                    contentsOf: $0.makeTransitions(given: row.givenStates)
                )
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
    
    func executeEntryActions(nextState: S) {
        if let entries = entryActions[nextState]  {
            entries.executeAll()
        }
    }
    
    func executeExitActions(currentState: S) {
        if let exits = exitActions[currentState] {
            exits.executeAll()
        }
    }
}

class FSM<S: SP, E: EP>: FSMBase<S, E> {
    func handleEvent(_ event: E) {
        let key = K(state: state, event: event)

        if let t = transitionTable[key] {
            t.actions.executeAll()

            if state != t.nextState {
                executeExitActions(currentState: state)
                executeEntryActions(nextState: t.nextState)

                state = t.nextState
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
        "States and Events must not inherit from NSObject, or include NSObject instances"
    }
}

extension SuperState {
    func makeTransitions(
        given states: any Collection<S>
    ) -> [Transition<S, E>] {
        states.reduce(into: [Transition]()) { ts, state in
            wtas.forEach {
                ts.append(contentsOf: $0.makeTransitions(given: state))
            }
        }
    }
}

extension WTAP {
    func makeTransitions(given state: S) -> [Transition<S, E>] {
        events.reduce(into: [Transition]()) {
            $0.append(Transition(g: state,
                                 w: $1,
                                 t: self.state ?? state,
                                 a: actions,
                                 p: match.any,
                                 f: file,
                                 l: line))
        }
    }
}

private extension String {
    var name: String {
        URL(string: self)?.lastPathComponent ?? self
    }
}
