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
    func when(_ events: Event..., file: String = #file, line: Int = #line) -> Syntax.When<Event> {
        Syntax.When(events, file: file, line: line)
    }
}

enum Syntax {
    struct When<Event: Hashable> {
        let node: WhenNode
        
        init(_ events: [Event], file: String = #file, line: Int = #line) {
            node = WhenNode(events: events.map { AnyTraceable(base: $0,
                                                              file: file,
                                                              line: line) },
                            caller: "when",
                            file: file,
                            line: line)
        }
    }
}
