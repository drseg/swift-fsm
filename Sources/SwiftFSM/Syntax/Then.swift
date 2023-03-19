//
//  Then.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Then<State: Hashable>: MWASyntaxBlock {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> Internal.MatchingThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: ThenNode
        let file: String
        let line: Int
        
        var blockNode: ThenBlockNode {
            ThenBlockNode(state: node.state,
                          rest: node.rest,
                          caller: "then",
                          file: file,
                          line: line)
        }
        
        init(_ state: State? = nil, file: String = #file, line: Int = #line) {
            node = ThenNode(
                state: state != nil ? AnyTraceable(base: state!,
                                                   file: file,
                                                   line: line): nil
            )
            self.file = file
            self.line = line
        }
    }
}
