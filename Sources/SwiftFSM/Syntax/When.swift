//
//  When.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct When<Event: Hashable> {
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> Internal.MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func | (lhs: Self, rhs: @escaping () -> ()) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        static func |<State: Hashable> (lhs: Self, rhs: Then<State>) -> Internal.MatchingWhenThenActions {
            .init(node: ActionsNode(actions: [], rest: [rhs.node.appending(lhs.node)]))
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
        
        init(
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
}
