//
//  File.swift
//  
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
    
    func combineWithRest(_ : [Never]) -> [Action] {
        actions
    }
}

typealias ThenOutput = (state: AnyTraceable?, actions: [Action])

struct FinalThenNode: Node {
    let state: AnyTraceable?
    var rest: [any Node<Input>] = []
    
    func combineWithRest(_ rest: [FinalActionsNode.Output]) -> [ThenOutput] {
        [(state: state, actions: rest)]
    }
}

typealias WhenOutput = (event: AnyTraceable,
                        state: AnyTraceable?,
                        actions: [Action])

struct FinalWhenNode: Node {
    let events: [AnyTraceable]
    var rest: [any Node<Input>] = []
    
    func combineWithRest(_ rest: [FinalThenNode.Output]) -> [WhenOutput] {
        events.reduce(into: [Output]()) {
            $0.append(
                (event: $1,
                 state: rest.first?.state,
                 actions: rest.first?.actions ?? [])
            )
        }
    }
}

struct GivenNode: Node {
    typealias Output = (state: AnyTraceable,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    let states: [AnyTraceable]
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
    typealias Output = (state: AnyTraceable,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action],
                        entryActions: [Action],
                        exitActions: [Action])
    
    let entryActions: [Action]
    let exitActions: [Action]
    var rest: [any Node<GivenNode.Output>] = []
    
    func combineWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append((state: $1.state,
                       event: $1.event,
                       nextState: $1.nextState,
                       actions: $1.actions,
                       entryActions:
                        $1.state == $1.nextState ? [] : entryActions,
                       exitActions:
                        $1.state == $1.nextState ? [] : exitActions))
        }
    }
}

struct EmptyBuilderBlockError: Error {
    let callingFunction: String
    let file: String
    let line: Int
    
    init(callingFunction: String = #function, file: String, line: Int) {
        self.callingFunction = String(callingFunction.prefix { $0 != "(" })
        self.file = file
        self.line = line
    }
}
