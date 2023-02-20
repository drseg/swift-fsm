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

struct FinalActionsNode: Node {
    typealias Input = Never
    typealias Output = () -> ()
    
    let actions: [() -> ()]
    let rest: [any Node<Never>] = []
    
    func combineWithRest(_ rest: [Never]) -> [() -> ()] {
        actions
    }
}

struct FinalThenNode: Node {
    typealias Input = FinalActionsNode.Output
    typealias Output = (state: AnyHashable, actions: [Input])
    
    let state: AnyHashable
    var rest: [any Node<FinalActionsNode.Output>] = []
    
    func combineWithRest(
        _ rest: [() -> ()]
    ) -> [Output] {
        [(state: state, actions: rest)]
    }
}

struct FinalWhenNode: Node {
    typealias Input = FinalThenNode.Output
    typealias Output = (events: [AnyHashable],
                        state: AnyHashable?,
                        actions: [FinalActionsNode.Output])
    
    let events: [AnyHashable]
    var rest: [any Node<FinalThenNode.Output>] = []
    
    func combineWithRest(_ rest: [FinalThenNode.Output]) -> [Output] {
        [(events: events,
          state: rest.first?.state,
          actions: rest.first?.actions ?? [])]
    }
}

struct TableRow {
    let state: AnyHashable?
    let errors: [EmptyBuilderBlockError]
    let entryActions: [() -> ()]
    let exitActions: [() -> ()]
    
    init(
        state: AnyHashable? = nil,
        errors: [EmptyBuilderBlockError] = [],
        entryActions: [() -> ()] = [],
        exitActions: [() -> ()] = []
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
