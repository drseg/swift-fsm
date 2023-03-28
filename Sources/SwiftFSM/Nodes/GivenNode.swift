//
//  GivenNode.swift
//  
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

struct GivenNode: Node {
    typealias Output = (state: AnyTraceable,
                        match: Match,
                        event: AnyTraceable,
                        nextState: AnyTraceable,
                        actions: [Action])
    
    let states: [AnyTraceable]
    var rest: [any Node<DefaultIO>] = []
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [Output] {
        states.reduce(into: []) { result, state in
            rest.forEach {
                result.append(
                    (state: state,
                     match: $0.match,
                     event: $0.event!,
                     nextState: $0.state ?? state,
                     actions: $0.actions)
                )
            }
        }
    }
}
