//
//  WhenNode.swift
//  
//  Created by Daniel Segall on 14/03/2023.
//

import Foundation

class WhenNodeBase {
    let events: [AnyTraceable]
    var rest: [any Node<DefaultIO>]
    
    let caller: String
    let file: String
    let line: Int
    
    init(
        events: [AnyTraceable],
        rest: [any Node<DefaultIO>] = [],
        caller: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        self.events = events
        self.rest = rest
        self.caller = caller
        self.file = file
        self.line = line
    }
    
    func combinedWithRest(_ rest: [DefaultIO]) -> [DefaultIO] {
        events.reduce(into: [DefaultIO]()) { output, event in
            output.append(contentsOf: rest.reduce(into: [DefaultIO]()) {
                $0.append(
                    (match: $1.match,
                     event: event,
                     state: $1.state,
                     actions: $1.actions)
                )
            } ??? defaultIOOutput(event: event))
        }
    }
}

class WhenNode: WhenNodeBase, NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: events.isEmpty)
    }
}

class WhenBlockNode: WhenNodeBase, NeverEmptyNode {
    func validate() -> [Error] {
        makeError(if: events.isEmpty || rest.isEmpty)
    }
}
