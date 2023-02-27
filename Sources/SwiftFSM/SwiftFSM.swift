//
//  SwiftFSM.swift
//
//  Created by Daniel Segall on 19/02/2023.
//

import Foundation

typealias Action = () -> ()

struct AnyTraceable {
    let base: AnyHashable
    let file: String
    let line: Int
    
    init(base: AnyHashable, file: String, line: Int) {
        self.base = base
        self.file = file
        self.line = line
    }
}

extension AnyTraceable: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.base == rhs.base
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

struct FinalActionsNode: Node {
    let actions: [Action]
    let rest: [any Node<Never>] = []
    
    func combinedWithRest(_ : [Never]) -> [Action] {
        actions
    }
}

typealias ThenOutput = (state: AnyTraceable?, actions: [Action])

struct FinalThenNode: Node {
    let state: AnyTraceable?
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [FinalActionsNode.Output]) -> [ThenOutput] {
        [(state: state, actions: rest)]
    }
}

typealias WhenOutput = (event: AnyTraceable,
                        state: AnyTraceable?,
                        actions: [Action])

struct FinalWhenNode: Node {
    let events: [AnyTraceable]
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [FinalThenNode.Output]) -> [WhenOutput] {
        events.reduce(into: [Output]()) {
            $0.append(
                (event: $1,
                 state: rest.first?.state,
                 actions: rest.first?.actions ?? [])
            )
        }
    }
}

struct FinalMatchNode: Node {
    typealias Output = (match: Match,
                        event: AnyTraceable,
                        state: AnyTraceable?,
                        actions: [Action])
    
    let match: Match
    var rest: [any Node<Input>] = []
    
    var caller = #function
    var file = #file
    var line = #line
    
    func combinedWithRest(_ rest: [WhenOutput]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append(
                (match: match,
                 event: $1.event,
                 state: $1.state,
                 actions: $1.actions)
            )
        }
    }
    
    func validate() -> [Error] {
        rest.isEmpty
        ? [EmptyBuilderError(caller: caller, file: file, line: line)]
        : []
    }
}

struct GivenNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    let states: [AnyTraceable]
    var rest: [any Node<WhenOutput>] = []
    
    func combinedWithRest(_ rest: [WhenOutput]) -> [Output] {
        states.reduce(into: [Output]()) { result, state in
            rest.forEach {
                result.append((state: state,
                               match: Match(),
                               event: $0.event,
                               nextState: $0.state ?? state,
                               actions: $0.actions))
            }
        }
    }
}

struct DefineNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action],
                        entryActions: [Action],
                        exitActions: [Action])
    
    let entryActions: [Action]
    let exitActions: [Action]
    var rest: [any Node<GivenNode.Output>] = []
    var caller = #function
    var file = #file
    var line = #line
    
    func combinedWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append((state: $1.state,
                       match: $1.match,
                       event: $1.event,
                       nextState: $1.nextState,
                       actions: $1.actions,
                       entryActions:
                        $1.state == $1.nextState ? [] : entryActions,
                       exitActions:
                        $1.state == $1.nextState ? [] : exitActions))
        }
    }
    
    func validate() -> [Error] {
        rest.isEmpty
        ? [EmptyBuilderError(caller: caller, file: file, line: line)]
        : []
    }
}

struct EmptyBuilderError: Error, Equatable {
    let caller: String
    let file: String
    let line: Int
    
    init(caller: String = #function, file: String, line: Int) {
        self.caller = String(caller.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
}
