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
                      file: file,
                      line: line,
                      elements: [])
    }
    
    func define(
        _ s1: State,
        _ rest: State...,
        superState: SuperState? = nil,
        entryActions: [() -> ()],
        exitActions: [() -> ()],
        file: String = #file,
        line: Int = #line,
        @Syntax._MWTABuilder _ block: () -> ([any SyntaxElement])
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
}

protocol SyntaxElement {
    associatedtype NodeType: Node<DefaultIO>
    var node: NodeType { get }
}

enum Syntax {
    struct Matching {
        static func |<State: Hashable> (lhs: Self, rhs: When<State>) -> _MatchingWhen {
            _MatchingWhen(node: rhs.node.appending(lhs.node))
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
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _WhenThen {
            _WhenThen(node: rhs.node.appending(lhs.node))
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
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _ThenActions {
            _ThenActions(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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
                      file: file,
                      line: line,
                      elements: [])
        }
        
        init(_ s1: State,
             _ rest: State...,
             superState: SuperState? = nil,
             entryActions: [() -> ()],
             exitActions: [() -> ()],
             file: String = #file,
             line: Int = #line,
             @Syntax._MWTABuilder _ block: () -> ([any SyntaxElement])
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
                         @Syntax._MWTABuilder _ block: () -> ([any SyntaxElement])
        ) {
            let elements = block()
            
            self.init(states,
                      superState: elements.isEmpty ? nil : superState,
                      entryActions: entryActions,
                      exitActions: exitActions,
                      file: file,
                      line: line,
                      elements: elements)
        }
        
        fileprivate init(_ states: [State],
                         superState: SuperState?,
                         entryActions: [() -> ()],
                         exitActions: [() -> ()],
                         file: String = #file,
                         line: Int = #line,
                         elements: [any SyntaxElement]
        ) {
            var dNode = DefineNode(entryActions: entryActions,
                                   exitActions: exitActions,
                                   caller: "define",
                                   file: file,
                                   line: line)
            
            if superState != nil || !elements.isEmpty {
                let nodes = elements.map { $0.node as! any Node<DefaultIO> }
                let gNode = GivenNode(states: states.map {
                    AnyTraceable(base: $0, file: file, line: line)
                },
                                      rest: superState?.nodes ?? [] + nodes)
                
                dNode.rest = [gNode]
            }
            
            self.node = dNode
        }
    }
    
    struct _ThenActions {
        let node: ActionsNode
    }
    
    struct _MatchingWhen {
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MatchingWhenThen {
            _MatchingWhenThen(node: rhs.node.appending(lhs.node))
        }
        
        let node: WhenNode
    }
    
    struct _WhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _WhenThenActions {
            _WhenThenActions(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct _WhenThenActions: SyntaxElement {
        let node: ActionsNode
    }
    
    struct _MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _MatchingWhenThenActions {
            _MatchingWhenThenActions(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct _MatchingWhenThenActions: SyntaxElement {
        let node: ActionsNode
    }
    
    @resultBuilder
    struct _MWTABuilder: ResultBuilder {
        typealias T = any SyntaxElement
    }
}

struct SuperState {
    var nodes: [any Node<DefaultIO>]
    
    init(@Syntax._MWTABuilder _ block: () -> ([any SyntaxElement])) {
        nodes = block().map { $0.node as! any Node<DefaultIO> }
    }
}

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}
