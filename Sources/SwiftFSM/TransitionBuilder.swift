//
//  TransitionBuilder.swift
//
//  Created by Daniel Segall on 03/03/2023.
//

import Foundation

protocol TransitionBuilder {
    associatedtype State: Hashable
    associatedtype Event: Hashable
}

extension TransitionBuilder {
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState,
        entryActions: [() -> ()],
        exitActions: [() -> ()],
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Define<State> {
        Syntax.Define([s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      elements: [],
                      file: file,
                      line: line)
    }
    
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState? = nil,
        entryActions: [() -> ()],
        exitActions: [() -> ()],
        file: String = #file,
        line: Int = #line,
        @Syntax._SentenceBuilder _ block: () -> ([any Sentence])
    ) -> Syntax.Define<State> {
        Syntax.Define(states: [s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      file: file,
                      line: line,
                      block)
    }
    
    func matching(
        _ p: any Predicate,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(p, file: file, line: line)
    }
    
    func matching(
        any: any Predicate,
        _ any2: any Predicate,
        _ anyRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [any, any2] + anyRest, all: [], file: file, line: line)
    }
    
    func matching(
        all: any Predicate,
        _ all2: any Predicate,
        _ allRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [], all: [all, all2] + allRest, file: file, line: line)
    }
    
    func matching(
        any: any Predicate,
        _ any2: any Predicate,
        _ anyRest: any Predicate...,
        all: any Predicate,
        _ all2: any Predicate,
        _ allRest: any Predicate...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Matching {
        .init(any: [any, any2] + anyRest, all: [all, all2] + allRest, file: file, line: line)
    }
    
    func when(
        _ first: Event,
        _ rest: Event...,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.When<Event> {
        .init([first] + rest, file: file, line: line)
    }
    
    func then(
        _ state: State? = nil,
        file: String = #file,
        line: Int = #line
    ) -> Syntax.Then<State> {
        .init(state, file: file, line: line)
    }
    
    func actions(
        _ a1: @escaping () -> (),
        _ aRest: () -> ()...,
        file: String = #file,
        line: Int = #line,
        @Syntax._SentenceBuilder _ block: () -> ([any Sentence])
    ) -> Syntax._ActionsSentence {
        Syntax.Actions([a1] + aRest, file: file, line: line)(block)
    }
}

protocol Sentence {
    associatedtype N: Node<DefaultIO>
    var node: N { get }
}

enum Syntax {
    struct Matching {
        static func |<State: Hashable> (lhs: Self, rhs: When<State>) -> _MW {
            _MW(node: rhs.node.appending(lhs.node))
        }
        
        let node: MatchNode
        
        init(_ p: any Predicate, file: String = #file, line: Int = #line) {
            self.init(any: [], all: [p], file: file, line: line)
        }
        
        init(
            any: any Predicate,
            _ any2: any Predicate,
            _ anyRest: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(any: [any, any2] + anyRest, all: [], file: file, line: line)
        }
        
        init(
            all: any Predicate,
            _ all2: any Predicate,
            _ allRest: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(any: [], all: [all, all2] + allRest, file: file, line: line)
        }
        
        init(
            any: any Predicate,
            _ any2: any Predicate,
            _ anyRest: any Predicate...,
            all: any Predicate,
            _ all2: any Predicate,
            _ allRest: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(any: [any, any2] + anyRest,
                      all: [all, all2] + allRest,
                      file: file,
                      line: line)
        }
        
        fileprivate init(
            any: [any Predicate],
            all: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            node = MatchNode(match: Match(any: any.erase(), all: all.erase()),
                             caller: "match",
                             file: file,
                             line: line)
        }
    }
    
    struct When<Event: Hashable> {
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MWT {
            _MWT(node: rhs.node.appending(lhs.node))
        }
        
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MWTA {
            _MWTA(node: ActionsNode(actions: [], rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: WhenNode
        
        init(
            _ first: Event,
            _ rest: Event...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([first] + rest, file: file, line: line)
        }
        
        fileprivate init(
            _ events: [Event],
            file: String,
            line: Int
        ) {
            node = WhenNode(
                events: events.map { AnyTraceable(base: $0, file: file, line: line) },
                caller: "when",
                file: file,
                line: line
            )
        }
    }
    
    struct Then<State: Hashable> {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _TA {
            _TA(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
        
        init(_ state: State? = nil, file: String = #file, line: Int = #line) {
            node = ThenNode(
                state: state != nil ? AnyTraceable(base: state,
                                                   file: file,
                                                   line: line): nil
            )
        }
    }
    
    struct Define<State: Hashable> {
        let node: DefineNode
        
        init(_ s1: State,
             _ rest: State...,
             superState: SuperState,
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line
        ) {
            self.init([s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      elements: [],
                      file: file,
                      line: line)
        }
        
        init(_ s1: State,
             _ rest: State...,
             superState: SuperState? = nil,
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Syntax._SentenceBuilder _ block: () -> ([any Sentence])
        ) {
            self.init(states: [s1] + rest,
                      superState: superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      file: file,
                      line: line,
                      block)
        }
        
        fileprivate init(states: [State],
                         superState: SuperState? = nil,
                         entryActions: [() -> ()],
                         exitActions: [() -> ()],
                         file: String = #file,
                         line: Int = #line,
                         @Syntax._SentenceBuilder _ block: () -> ([any Sentence])
        ) {
            let elements = block()
            
            self.init(states,
                      superState: elements.isEmpty ? nil : superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      elements: elements,
                      file: file,
                      line: line)
        }
        
        fileprivate init(_ states: [State],
                         superState: SuperState?,
                         entryActions: [() -> ()],
                         exitActions: [() -> ()],
                         elements: [any Sentence],
                         file: String = #file,
                         line: Int = #line
        ) {
            var dNode = DefineNode(entryActions: entryActions,
                                   exitActions: exitActions,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            let isValid = superState != nil || !elements.isEmpty
            
            if isValid {
                func eraseToAnyTraceable(_ s: State) -> AnyTraceable {
                    AnyTraceable(base: s, file: file, line: line)
                }
                
                let states = states.map(eraseToAnyTraceable)
                let rest = superState?.nodes ?? [] + elements.nodes
                let gNode = GivenNode(states: states, rest: rest)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
    
    struct _TA {
        let node: ActionsNode
    }
    
    struct _MW {
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MWT {
            _MWT(node: rhs.node.appending(lhs.node))
        }
        
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MWTA {
            _MWTA(node: ActionsNode(actions: [], rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: WhenNode
    }
    
    struct _MWT {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _MWTA {
            _MWTA(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct _MWTA: Sentence {
        let node: ActionsNode
    }
    
    struct Actions {
        let actions: [() -> ()]
        let file: String
        let line: Int
        
        init(_ actions: @escaping () -> (), file: String = #file, line: Int = #line) {
            self.init([actions], file: file, line: line)
        }
        
        init(_ actions: [() -> ()], file: String = #file, line: Int = #line) {
            self.actions = actions
            self.file = file
            self.line = line
        }
        
        func callAsFunction(
            @_SentenceBuilder _ block: () -> ([any Sentence])
        ) -> _ActionsSentence {
            _ActionsSentence(actions, file: file, line: line, block)
        }
    }
    
    struct _ActionsSentence: Sentence {
        let node: ActionsBlockNode
    
        init(
            _ actions: [() -> ()],
            file: String = #file,
            line: Int = #line,
            @_SentenceBuilder _ block: () -> ([any Sentence])
        ) {
            node = ActionsBlockNode(
                actions: actions,
                rest: block().nodes,
                caller: "actions",
                file: file,
                line: line
            )
        }
    }
    
    @resultBuilder
    struct _SentenceBuilder: ResultBuilder {
        typealias T = any Sentence
    }
}

struct SuperState {
    var nodes: [any Node<DefaultIO>]
    
    init(@Syntax._SentenceBuilder _ block: () -> ([any Sentence])) {
        nodes = block().nodes
    }
}

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}

extension [Sentence] {
    var nodes: [any Node<DefaultIO>] {
        map { $0.node as! any Node<DefaultIO> }
    }
}
