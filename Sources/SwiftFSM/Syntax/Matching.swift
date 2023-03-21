//
//  Matching.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Matching {
        static func |<E: Hashable> (lhs: Self, rhs: When<E>) -> Internal.MatchingWhen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func |<E: Hashable> (lhs: Self, rhs: When<E>) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        static func |<S: Hashable> (lhs: Self, rhs: Then<S>) -> Internal.MatchingThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func |<S: Hashable> (lhs: Self, rhs: Then<S>) -> Internal.MatchingThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        let node: MatchNode
        let file: String
        let line: Int
        
        var blockNode: MatchBlockNode {
            MatchBlockNode(match: node.match,
                           rest: node.rest,
                           caller: "match",
                           file: file,
                           line: line)
        }
        
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
            node = MatchNode(match: Match(any: any.erased(), all: all.erased()), rest: [])
            self.file = file
            self.line = line
        }
        
        func callAsFunction(
            @Internal.MWTABuilder _ block: () -> ([any MWTA])
        ) -> Internal.MWTASentence {
            .init(blockNode, block)
        }
        
        func callAsFunction(
            @Internal.MWABuilder _ block: () -> ([any MWA])
        ) -> Internal.MWASentence {
            .init(blockNode, block)
        }
        
        func callAsFunction(
            @Internal.MTABuilder _ block: () -> ([any MTA])
        ) -> Internal.MTASentence {
            .init(blockNode, block)
        }
    }
}
