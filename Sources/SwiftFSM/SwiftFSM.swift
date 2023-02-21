//
//  File.swift
//  
//
//  Created by Daniel Segall on 19/02/2023.
//

import Foundation

protocol TransitionBuilderProtocol {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}

extension TransitionBuilderProtocol {
    func define(
        _ state: State,
        _ line: Int = #line,
        _ file: String = #file,
        @TableRowBuilder _ block: () -> [TableRow]
    ) -> [TableRow] {
        let rows = block()
        
        guard !rows.isEmpty else {
            return  [TableRow(errors: [.init(file: file,
                                             line: line)])]
        }
        
        return rows.reduce(into: [TableRow]()) {
            $0.append(TableRow(state: state,
                               errors: $1.errors,
                               entryActions: $1.entryActions,
                               exitActions: $1.exitActions))
        }
    }
    
    func entryActions(_ actions: () -> ()...) -> TableRow {
        entryActions(actions)
    }
    
    func entryActions(_ actions: [() -> ()]) -> TableRow {
        TableRow(entryActions: actions)
    }
    
    func exitActions(_ actions: () -> ()...) -> TableRow {
        exitActions(actions)
    }
    
    func exitActions(_ actions: [() -> ()]) -> TableRow {
        TableRow(exitActions: actions)
    }
}

typealias Action = () -> ()

struct FinalActionsNode: Node {
    typealias Output = Action
    
    let actions: [Output]
    let rest: [any Node<Never>] = []
    
    func combineWithRest(_ : [Never]) -> [Output] {
        actions
    }
}

typealias ThenOutput = (state: AnyHashable?, actions: [() -> ()])

struct FinalThenNode: Node {
    let state: AnyHashable?
    var rest: [any Node<Input>] = []
    
    func combineWithRest(_ rest: [FinalActionsNode.Output]) -> [ThenOutput] {
        [(state: state, actions: rest)]
    }
}

typealias WhenOutput = (event: AnyHashable,
                        state: AnyHashable?,
                        actions: [Action])

struct FinalWhenNode: Node {
    let events: [AnyHashable]
    var rest: [any Node<Input>] = []
    
    func combineWithRest(_ rest: [FinalThenNode.Output]) -> [WhenOutput] {
        events.reduce(into: [Output]()) {
            $0.append((
                event: $1,
                state: rest.first?.state,
                actions: rest.first?.actions ?? [])
            )
        }
    }
}

struct GivenNode: Node {
    typealias Output = (state: AnyHashable,
                        event: AnyHashable,
                        nextState: AnyHashable,
                        actions: [Action])
    
    let states: [AnyHashable]
    var rest: [any Node<WhenOutput>] = []
    
    func combineWithRest(_ rest: [WhenOutput]) -> [Output] {
        states.reduce(into: [Output]()) { result, state in
            rest.forEach {
                result.append((state: state,
                               event: $0.event,
                               nextState: $0.state ?? state,
                               actions: $0.actions))
            }
        }
    }
}

struct DefineNode: Node {
    typealias Output = (state: AnyHashable,
                        event: AnyHashable,
                        nextState: AnyHashable,
                        actions: [Action],
                        entryActions: [Action],
                        exitActions: [Action])
    
    let entryActions: [Action]
    let exitActions: [Action]
    var rest: [any Node<GivenNode.Output>]
    
    func combineWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append((state: $1.state,
                       event: $1.event,
                       nextState: $1.nextState,
                       actions: $1.actions,
                       entryActions:
                        $1.state == $1.nextState
                            ? [] : entryActions,
                       exitActions:
                        $1.state == $1.nextState
                            ? [] : exitActions))
        }
    }
}

struct TableRow {
    let state: AnyHashable?
    let errors: [EmptyBuilderBlockError]
    let entryActions: [Action]
    let exitActions: [Action]
    
    init(
        state: AnyHashable? = nil,
        errors: [EmptyBuilderBlockError] = [],
        entryActions: [Action] = [],
        exitActions: [Action] = []
    ) {
        self.state = state
        self.errors = errors
        self.entryActions = entryActions
        self.exitActions = exitActions
    }
}

struct EmptyBuilderBlockError: Error {
    let callingFunction: String
    let file: String
    let line: Int
    
    init(callingFunction: String = #function,file: String, line: Int) {
        self.callingFunction = String(callingFunction.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
}
