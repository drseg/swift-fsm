//
//  Then.swift
//
//  Created by Daniel Segall on 07/03/2023.
//

import Foundation

extension Syntax {
    struct Then<State: Hashable> {
        static func | (lhs: Self, rhs: @escaping () -> ()) -> Internal.ThenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
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
}
