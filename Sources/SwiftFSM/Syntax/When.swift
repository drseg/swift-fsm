import Foundation

public extension Syntax {
    struct When<Event: Hashable> {
        public static func | <S: Hashable> (
            lhs: Self, 
            rhs: Then<S>
        ) -> Internal.MatchingWhenThen {
            .init(node: rhs.node.appending(lhs.node))
        }

        public static func | <S: Hashable> (
            lhs: Self,
            rhs: Then<S>
        ) -> Internal.MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping Action
        ) -> Internal.MatchingWhenActions {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        let node: WhenNode

        var blockNode: WhenBlockNode {
            WhenBlockNode(events: node.events,
                          caller: node.caller,
                          file: node.file,
                          line: node.line)
        }

        public init(
            _ event: Event,
            or otherEvents: Event...,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([event] + otherEvents, file: file, line: line)
        }

        public init(
            _ event: Event,
            file: String = #file,
            line: Int = #line
        ) {
            self.init([event], file: file, line: line)
        }

        public init(
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

        public func callAsFunction(
            @Internal.MTABuilder _ block: () -> [MTA]
        ) -> Internal.MWTASentence {
            .init(blockNode, block)
        }

        public func callAsFunction(
            @Internal.MABuilder _ block: () -> [MA]
        ) -> Internal.MWASentence {
            .init(blockNode, block)
        }
    }
}
