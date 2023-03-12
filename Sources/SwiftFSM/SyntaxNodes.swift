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

protocol NeverEmptyNode: Node {
    var caller: String { get }
    var file: String { get }
    var line: Int { get }
}

extension NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: rest.isEmpty)
    }
    
    fileprivate func makeError(if predicate: Bool) -> [Error] {
        predicate
        ? [EmptyBuilderError(caller: caller, file: file, line: line)]
        : []
    }
}

typealias DefaultIO = (match: Match,
                       event: AnyTraceable?,
                       state: AnyTraceable?,
                       actions: [Action])

class ActionsNodeBase {
    let actions: [Action]
    var rest: [any Node<DefaultIO>]
    
    init(actions: [Action] = [], rest: [any Node<DefaultIO>] = []) {
        self.actions = actions
        self.rest = rest
    }
    
    #warning("why does this have a special 'isEmpty ? []' check unlike any others?")
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        actions.isEmpty ? [] : rest.reduce(into: [DefaultIO]()) {
            $0.append((match: $1.match,
                       event: $1.event,
                       state: $1.state,
                       actions: actions + $1.actions))
        } ??? [(match: Match(), event: nil, state: nil, actions: actions)]
    }
}

class ActionsNode: ActionsNodeBase, Node { }

class ActionsBlockNode: ActionsNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        actions: [Action],
        rest: [any Node<Input>],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(actions: actions, rest: rest)
    }
}

class ThenNodeBase {
    let state: AnyTraceable?
    var rest: [any Node<DefaultIO>]
    
    init(state: AnyTraceable?, rest: [any Node<DefaultIO>] = []) {
        self.state = state
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: [DefaultIO]()) {
            $0.append((match: $1.match,
                       event: $1.event,
                       state: state,
                       actions: $1.actions))
        } ??? [(match: Match(), event: nil, state: state, actions: [])]
    }
}

class ThenNode: ThenNodeBase, Node { }

class ThenBlockNode: ThenNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        state: AnyTraceable?,
        rest: [any Node<Input>],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(state: state, rest: rest)
    }
}

class WhenNodeBase {
    let events: [AnyTraceable]
    var rest: [any Node<DefaultIO>]
    
    let caller: String
    let file: String
    let line: Int
    
    init(
        events: [AnyTraceable],
        rest: [any Node<DefaultIO>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.events = events
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }
    
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

class WhenNode: WhenNodeBase, NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: events.isEmpty)
    }
}

class WhenBlockNode: WhenNodeBase, NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: events.isEmpty || rest.isEmpty)
    }
}

class MatchNodeBase {
    let match: Match
    var rest: [any Node<DefaultIO>]
    
    init(match: Match, rest: [any Node<DefaultIO>] = []) {
        self.match = match
        self.rest = rest
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        rest.reduce(into: [DefaultIO]()) {
            $0.append(
                (match: $1.match.prepend(match),
                 event: $1.event,
                 state: $1.state,
                 actions: $1.actions)
            )
        } ??? [(match: match, event: nil, state: nil, actions: [])]
    }
}

class MatchNode: MatchNodeBase, Node { }

class MatchBlockNode: MatchNodeBase, NeverEmptyNode {
    let caller: String
    let file: String
    let line: Int
    
    init(
        match: Match,
        rest: [any Node<Input>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.caller = caller
        self.file = file
        self.line = line
        
        super.init(match: match, rest: rest)
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

final class DefineNode: NeverEmptyNode {
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
    
    let caller: String
    let file: String
    let line: Int
        
    private var errors: [Error] = []
    
    init(
        entryActions: [Action],
        exitActions: [Action],
        rest: [any Node<GivenNode.Output>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.entryActions = entryActions
        self.exitActions = exitActions
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }
    
    func combinedWithRest(_ rest: [GivenNode.Output]) -> [Output] {
        rest.reduce(into: [Output]()) {
            $0.append((state: $1.state,
                       match: finalised($1.match),
                       event: $1.event,
                       nextState: $1.nextState,
                       actions: $1.actions,
                       entryActions:
                        $1.state == $1.nextState ? [] : entryActions,
                       exitActions:
                        $1.state == $1.nextState ? [] : exitActions))
        }
    }
    
    private func finalised(_ m: Match) -> Match {
        switch m.finalise() {
        case .failure(let e): errors.append(e); return Match()
        case .success(let m): return m
        }
    }
    
    func validate() -> [Error] {
        makeError(if: rest.isEmpty) + errors
    }
}

typealias TableNodeOutput = (state: AnyTraceable,
                             predicates: PredicateResult,
                             event: AnyTraceable,
                             nextState: AnyTraceable,
                             actions: [Action],
                             entryActions: [Action],
                             exitActions: [Action])
 
final class PreemptiveTableNode: Node {
    var rest: [any Node<Input>] = []
    
    func combinedWithRest(_ rest: [DefineNode.Output]) -> [TableNodeOutput] {
        rest.reduce(into: [Output]()) { result, dno in
            let allPredicateCombinations = dno.match.allPredicateCombinations([])
            allPredicateCombinations.forEach {
                result.append(
                    (state: dno.state,
                     predicates: $0,
                     event: dno.event,
                     nextState: dno.nextState,
                     actions: dno.actions,
                     entryActions: dno.entryActions,
                     exitActions: dno.exitActions)
                )
            }
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

infix operator ???: AdditionPrecedence

func ???<T: Collection> (lhs: T, rhs: T) -> T {
    lhs.isEmpty ? rhs : lhs
}
