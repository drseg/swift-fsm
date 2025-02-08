import Foundation

public extension Syntax {
    struct When<State: FSMHashable, Event: FSMHashable> {
        public static func | (
            lhs: Self,
            rhs: Then<State, Event>
        ) -> MatchingWhenThen<Event> {
            .init(node: rhs.node.appending(lhs.node))
        }

        public static func | (
            lhs: Self,
            rhs: Then<State, Event>
        ) -> MatchingWhenThenActions {
            .init(node: ActionsNode(rest: [rhs.node.appending(lhs.node)]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMAction
        ) -> MatchingWhenActions {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: @escaping FSMActionWithEvent<Event>
        ) -> MatchingWhenActions {
            .init(node: ActionsNode(actions: [AnyAction(rhs)], rest: [lhs.node]))
        }

        public static func | (
            lhs: Self,
            rhs: [AnyAction]
        ) -> MatchingWhenActions {
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
            @MTABuilder _ block: () -> [MTA]
        ) -> MWTABlock {
            .init(blockNode, block)
        }

        public func callAsFunction(
            @MABuilder _ block: () -> [MA]
        ) -> MWABlock {
            .init(blockNode, block)
        }
    }
}
