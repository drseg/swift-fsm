import Foundation

extension Syntax {
    struct When<Event: Hashable> {
        static func |<S: Hashable> (lhs: Self, rhs: Then<S>) -> Internal.MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }
        
        static func |<S: Hashable> (lhs: Self, rhs: Then<S>) -> Internal.MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }
        
        static func | (lhs: Self, rhs: @escaping Action) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(actions: [rhs], rest: [lhs.node]))
        }
        
        let node: WhenNode
        
        var blockNode: WhenBlockNode {
            WhenBlockNode(events: node.events,
                          caller: node.caller,
                          file: node.file,
                          line: node.line)
        }
        
        init(
            _ first: Event,
            or rest: Event...,
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
            node = WhenNode(events: events.map { AnyTraceable($0, file: file, line: line) },
                            caller: "when",
                            file: file,
                            line: line
            )
        }
        
        func callAsFunction(
            @Internal.MTABuilder _ block: () -> [any MTA]
        ) -> Internal.MWTASentence {
            .init(blockNode, block)
        }
        
        func callAsFunction(
            @Internal.MABuilder _ block: () -> [any MA]
        ) -> Internal.MWASentence {
            .init(blockNode, block)
        }
    }
}
