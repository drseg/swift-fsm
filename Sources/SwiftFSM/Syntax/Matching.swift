//
//  Matching.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Matching {
        static func |<Event: Hashable> (lhs: Self, rhs: When<Event>) -> Internal.MatchingWhen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func |<Event: Hashable> (lhs: Self, rhs: When<Event>) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(actions: [], rest: [rhs.node.appending(lhs.node)]))
        }
        
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> Internal.MatchingThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> Internal.MatchingThenActions {
            .init(node: ActionsNode(actions: [], rest: [rhs.node.appending(lhs.node)]))
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
        
        init(
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
}
