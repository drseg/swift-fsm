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

typealias DefaultIO = (match: Match,
                       event: AnyTraceable?,
                       state: AnyTraceable?,
                       actions: [Action])

struct ActionsNode: Node {
    let actions: [Action]
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        actions.isEmpty ? [] : rest.reduce(into: [DefaultIO]()) {
            $0.append((match: $1.match,
                       event: $1.event,
                       state: $1.state,
                       actions: actions + $1.actions))
        } ??? [(match: Match(), event: nil, state: nil, actions: actions)]
    }
}

struct ThenNode: Node {
    let state: AnyTraceable?
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: [DefaultIO]()) {
            $0.append((match: $1.match,
                       event: $1.event,
                       state: state,
                       actions: $1.actions))
        } ??? [(match: Match(), event: nil, state: state, actions: [])]
    }
}

struct WhenNode: Node {
    let events: [AnyTraceable]
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        events.reduce(into: [DefaultIO]()) { output, event in
            output.append(contentsOf: rest.reduce(into: [DefaultIO]()) {
                $0.append((match: $1.match,
                           event: event,
                           state: $1.state,
                           actions: $1.actions))
            } ??? [(match: Match(), event: event, state: nil, actions: [])])
        }
    }
}

protocol NeverEmptyNode: Node {
    var caller: String { get }
    var file: String { get }
    var line: Int { get }
}

extension NeverEmptyNode {
    func validate() -> [Error] {
        rest.isEmpty
        ? [EmptyBuilderError(caller: caller, file: file, line: line)]
        : []
    }
}

struct MatchNode: NeverEmptyNode {
    let match: Match
    var rest: [any Node<Input>] = []
    
    var caller = #function
    var file = #file
    var line = #line
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: [Output]()) {
            $0.append(
                (match: $1.match.prepend(match),
                 event: $1.event,
                 state: $1.state,
                 actions: $1.actions)
            )
        }
    }
}

struct GivenNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    let states: [AnyTraceable]
    var rest: [any Node<DefaultIO>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [Output] {
        states.reduce(into: [Output]()) { result, state in
            rest.forEach {
                result.append((state: state,
                               match: $0.match,
                               event: $0.event!,
                               nextState: $0.state ?? state,
                               actions: $0.actions))
            }
        }
    }
}

struct DefineNode: NeverEmptyNode {
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

infix operator ???

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
