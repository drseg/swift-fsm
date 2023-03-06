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
        static func | (lhs: Self, rhs: @escaping () -> ()) -> Syntax._ThenActions {
            Syntax._ThenActions(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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
    
    struct _ThenActions {
        let node: ActionsNode
    }
    
    struct _MatchingWhen {
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> _MatchingWhenThen {
            _MatchingWhenThen(node: rhs.node.appending(lhs.node))
        }
        
        let node: WhenNode
    }
    
    struct _MatchingWhenThen {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> _MatchingWhenThenActions {
            _MatchingWhenThenActions(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
    }
    
    struct _MatchingWhenThenActions {
        let node: ActionsNode
    }
}

extension Node {
    func appending<Other: Node>(_ other: Other) -> Self where Input == Other.Output {
        var this = self
        this.rest = [other]
        return this
    }
}
