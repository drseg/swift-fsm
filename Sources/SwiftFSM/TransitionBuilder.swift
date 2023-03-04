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
        let node: MatchNode
        
        init(_ p: any Predicate, file: String = #file, line: Int = #line) {
            self.init(Match(any: [], all: [p.erase()]), file: file, line: line)
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
            self.init(Match(any: any.erase(),
                            all: all.erase()),
                      file: file,
                      line: line)
        }
        
        
        fileprivate init(_ m: Match, file: String = #file, line: Int = #line) {
            node = MatchNode(match: m,
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
        let node: ThenNode
        
        init(_ state: State? = nil, file: String = #file, line: Int = #line) {
            node = ThenNode(
                state: state != nil ? AnyTraceable(base: state,
                                                   file: file,
                                                   line: line): nil
            )
        }
    }
}
