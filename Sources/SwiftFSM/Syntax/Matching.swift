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
        
        static func | (lhs: Self, rhs: @escaping () -> ()) -> Internal.MatchingActions {
            return .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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
        
        init(
            _ first: any Predicate,
            or: any Predicate...,
            and: any Predicate...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init(first, or: or, and: and, file: file, line: line)
        }
        
        init(
            _ first: any Predicate,
            or: [any Predicate],
            and: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            if or.isEmpty {
                self.init(any: [], all: [first] + and, file: file, line: line)
            } else {
                self.init(any: [first] + or, all: and, file: file, line: line)
            }
        }
        
        private init(
            any: [any Predicate],
            all: [any Predicate],
            file: String = #file,
            line: Int = #line
        ) {
            let match = Match(any: any.erased(),
                              all: all.erased(),
                              file: file,
                              line: line)
            
            self.node = MatchNode(match: match, rest: [])
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
