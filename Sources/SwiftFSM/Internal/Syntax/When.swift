import Foundation

public extension Internal {
    struct When<State: FSMHashable, Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: Then<State, Event>
        ) -> Internal.MatchingWhenThen<Event> {
            .init(node: rhs.node.appending(lhs.node))
        }

        public static func | (
            lhs: Self,
            rhs: Then<State, Event>
        ) -> Internal.MatchingWhenThenActions<Event> {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAction
        ) -> Internal.MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMActionWithEvent<Event>
        ) -> Internal.MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> Internal.MatchingWhenActions<Event> {
            .init(node: ActionsNode(actions: rhs, rest: [lhs.node]))
        }

        let node: WhenNode

        var blockNode: WhenBlockNode {
            WhenBlockNode(events: node.events,
                          caller: node.caller,
                          file: node.file,
                          line: node.line)
        }

        init(
            _ events: [Event],
            file: String,
            line: Int
        ) {
            node = WhenNode(
                events: events.map { AnyTraceable($0, file: file, line: line) },
                caller: "when",
                file: file,
                line: line
            )
        }

        public func callAsFunction(
            @Internal.MTABuilder _ block: () -> [MTA]
        ) -> Internal.MWTABlock {
            .init(blockNode, block)
        }

        public func callAsFunction(
            @Internal.MABuilder _ block: () -> [MA]
        ) -> Internal.MWABlock {
            .init(blockNode, block)
        }
    }
}
